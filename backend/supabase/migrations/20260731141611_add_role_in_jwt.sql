

--* This function runs when a user is signs-up in supabase auth ... adds role to JWT

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
as $$
declare
  user_role public.user_role;
begin

  select role
  into user_role
  from public.users
  where user_id = (event->>'user_id')::uuid;


  event := jsonb_set(
    event,
    '{claims,role}',
    to_jsonb(user_role)
  );


  return event;

end;
$$;

grant usage on schema public to supabase_auth_admin;

grant execute
on function public.custom_access_token_hook
to supabase_auth_admin;

--TODO: The Dashboard "Hooks → Custom Access Token Hook" (select the function defined above)  selection actually stores a configuration entry telling Supabase Auth