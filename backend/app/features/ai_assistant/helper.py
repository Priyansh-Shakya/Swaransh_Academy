



#* Removes Empty/Null fields from SQL fetched data we pass to LLM
def strip_empty(obj):
    if isinstance(obj, dict):
        return {k: strip_empty(v) for k, v in obj.items() if v not in (None, "", [])}
    if isinstance(obj, list):
        return [strip_empty(x) for x in obj]
    return obj



async def check_role(user, db):
    if user is None:
        print("Returning guest role ...")
        return 'guest'
    role = await db.fetchrow('select role from users where user_id = $1', user['id'])
    role = role['role'] if role else 'guest'
    print("Role fetched from DB: ", role)
    return role
