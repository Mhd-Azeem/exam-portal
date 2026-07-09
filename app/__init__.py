import os
from flask import Flask
from .config import config
from .extensions import db, jwt, login_manager, cors, migrate


def create_app(config_name='default'):
    app = Flask(__name__, template_folder='templates', static_folder='static')
    app.config.from_object(config[config_name])

    db.init_app(app)
    jwt.init_app(app)
    login_manager.init_app(app)
    cors.init_app(app, resources={r'/api/*': {'origins': '*'}})
    migrate.init_app(app, db)

    login_manager.login_view = 'web_auth.login'
    login_manager.login_message_category = 'info'

    @login_manager.user_loader
    def load_user(user_id):
        from .models import Student
        return Student.query.get(int(user_id))

    from .web.auth import web_auth_bp
    from .web.student import web_student_bp
    from .web.admin import web_admin_bp
    from .api.auth import api_auth_bp
    from .api.student import api_student_bp
    from .api.admin import api_admin_bp

    app.register_blueprint(web_auth_bp)
    app.register_blueprint(web_student_bp, url_prefix='/student')
    app.register_blueprint(web_admin_bp, url_prefix='/admin')
    app.register_blueprint(api_auth_bp, url_prefix='/api/auth')
    app.register_blueprint(api_student_bp, url_prefix='/api/student')
    app.register_blueprint(api_admin_bp, url_prefix='/api/admin')

    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

    with app.app_context():
        db.create_all()

    return app
