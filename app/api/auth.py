from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, create_refresh_token,
    jwt_required, get_jwt, get_jwt_identity,
)
from ..models import Student, Admin
from ..utils import error_response

api_auth_bp = Blueprint('api_auth', __name__)


def _make_tokens(role, user_id, extra_claims=None):
    additional = {'role': role, 'user_id': user_id}
    if extra_claims:
        additional.update(extra_claims)
    identity = f'{role}_{user_id}'
    access_token = create_access_token(identity=identity, additional_claims=additional)
    refresh_token = create_refresh_token(identity=identity, additional_claims={'role': role, 'user_id': user_id})
    return access_token, refresh_token


@api_auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json(silent=True)
    if not data:
        return error_response('Request body must be JSON', 400, 'BAD_REQUEST')

    username = (data.get('username') or '').strip()
    password = data.get('password') or ''

    if not username or not password:
        return error_response('username and password are required', 422, 'VALIDATION_ERROR')

    # Try student first (by index_number)
    student = Student.query.filter_by(index_number=username, is_active=True).first()
    if student and student.check_password(password):
        access_token, refresh_token = _make_tokens('student', student.id,
                                                    {'index_number': student.index_number})
        return jsonify({
            'access_token': access_token,
            'refresh_token': refresh_token,
            'role': 'student',
            'user': student.to_dict(),
        }), 200

    # Try admin (by username)
    admin = Admin.query.filter_by(username=username, is_active=True).first()
    if admin and admin.check_password(password):
        access_token, refresh_token = _make_tokens('admin', admin.id)
        return jsonify({
            'access_token': access_token,
            'refresh_token': refresh_token,
            'role': 'admin',
            'user': admin.to_dict(),
        }), 200

    return error_response('Invalid credentials', 401, 'INVALID_CREDENTIALS')


@api_auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    claims = get_jwt()
    role = claims.get('role')
    user_id = claims.get('user_id')
    identity = get_jwt_identity()
    additional = {'role': role, 'user_id': user_id}
    if role == 'student':
        student = Student.query.get(user_id)
        if student:
            additional['index_number'] = student.index_number
    new_access_token = create_access_token(identity=identity, additional_claims=additional)
    return jsonify({'access_token': new_access_token}), 200
