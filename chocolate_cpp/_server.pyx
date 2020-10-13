from webob import Request, Response
from parse import parse
from requests import Session as RequestsSession
from wsgiadapter import WSGIAdapter as RequestsWSGIAdapter
from jinja2 import Environment, FileSystemLoader
from whitenoise import WhiteNoise
from .middleware import *
import inspect,os
class Chocolate:
    def __init__(self,routes = None,templates_folder = "templates",assets_dir = "assets",
                     middleware = None, static_path = None):
        self.map = {} if routes == None else routes
        self.template_loader = Environment(
            loader=FileSystemLoader(
                os.path.abspath(templates_folder)
            )
        )
        self.exception_handler = None
        self.whitenoise = WhiteNoise(self.bot_handler, root=assets_dir)
        self.middleware = Middleware(self) if middleware == None else middleware
        self.static_path = "/static" if static_path == None else static_path
    def __call__(self, environ, start_response):
        path_info = environ["PATH_INFO"]

        if path_info.startswith(self.static_path):
            environ["PATH_INFO"] = path_info[len(self.static_path):]
            return self.whitenoise(environ, start_response)

        return self.middleware(environ, start_response)
    
    def bot_handler(self, environ, start_response):
        request = Request(environ)
        response = self.handle_request(request)
        return response(environ,start_response)
    
    def route(self, path):
        assert path not in self.map, (
            "Such route already exists."
            " Use '<app-variable>.delete(\"<path-name>\")' "
        )
        def wrapper(handler):
            self.map[path] = handler
            return handler

        return wrapper
    def find_handler(self, request_path):
        for path, handler in self.map.items():
            parse_result = parse(path, request_path)
            if parse_result is not None:
                return handler, parse_result.named
        return None, None
    def default_response(self, response):
        response.status_code = 404
        response.text = "Not found."
    def handle_request(self, request):
        response = Response()

        handler, kwargs = self.find_handler(request_path=request.path)

        if handler is not None:
            if inspect.isclass(handler):
                handler = getattr(handler(), request.method.lower(), None)
                if handler is None:
                    raise AttributeError("Method now allowed", request.method)

            handler(request, response, **kwargs)
        else:
            self.default_response(response)

        return response
    def delete(self,route_path):
        del self.map[route_path]
    def create_prototype_session(self, base_url="http://server"):
        session = RequestsSession()
        session.mount(prefix=base_url, adapter=RequestsWSGIAdapter(self))
        return session
    def add_route(self, path, handler):
        assert path not in self.map, (
            "Such route already exists."
            " Use '<app-variable>.delete(\"<path-name>\")' to replace the route."
        )

        self.map[path] = handler
    def render(self,file,**contexts):
        return self.template_loader.get_template(file).render(**contexts)
    def set_exception_handler(self, exception_handler):
        self.exception_handler = exception_handler
