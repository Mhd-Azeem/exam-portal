import os
from flask import jsonify
from math import ceil


ALLOWED_EXTENSIONS = {'pdf', 'doc', 'docx', 'ppt', 'pptx', 'mp4', 'png', 'jpg', 'jpeg', 'zip'}


def error_response(message, status_code=400, code='ERROR', details=None):
    body = {'error': True, 'message': message, 'code': code}
    if details:
        body['details'] = details
    return jsonify(body), status_code


def success_response(data, status_code=200, message=None):
    body = {'success': True, 'data': data}
    if message:
        body['message'] = message
    return jsonify(body), status_code


def paginate_query(query, page, per_page, serialize_fn=None):
    total_count = query.count()
    total_pages = ceil(total_count / per_page) if per_page > 0 else 1
    items = query.offset((page - 1) * per_page).limit(per_page).all()

    data = [serialize_fn(item) if serialize_fn else item for item in items]
    return {
        'data': data,
        'page': page,
        'per_page': per_page,
        'total_pages': total_pages,
        'total_count': total_count,
    }


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def parse_date(date_str):
    """Parse YYYY-MM-DD string to date object, return None on failure."""
    if not date_str:
        return None
    from datetime import date
    try:
        return date.fromisoformat(date_str)
    except (ValueError, TypeError):
        return None


def validate_mark_value(mark, total_marks):
    """Return (float_mark, error_msg) — error_msg is None on success."""
    try:
        m = float(mark)
        t = float(total_marks)
    except (TypeError, ValueError):
        return None, 'Mark and total_marks must be numeric'
    if t <= 0:
        return None, 'total_marks must be positive'
    if not (0 <= m <= t):
        return None, f'Mark {m} is out of range (0 – {t})'
    return m, None
