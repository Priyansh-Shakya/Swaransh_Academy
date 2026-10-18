
--* Enable extention for HTTP Request

create extension if not exists pg_net with schema extensions;


create or replace function check_student_birthdays()
returns void
language plpgsql
security definer
as $$
declare
  student record;
  backend_url text;
begin
  -- Fetch the backend URL dynamically from your config table
  -- (Adjust 'app_config', 'key', and 'value' to match your actual table/column names)
  select value into backend_url 
  from config 
  where key = 'backend_url';

  -- Handle case where configuration is missing
  if backend_url is null then
    raise exception 'Configuration error: "backend_url" not found in config table.';
  end if;
  -- Loop through students whose birthday is today, and grab their fcm_token from users table
  for student in 
    select s.id, s.scholar_no, s.name, s.department, u.fcm_token 
    from students s
    left join users u on s.user_id = u.user_id
    where extract(month from s.dob) = extract(month from current_date)
      and extract(day from s.dob) = extract(day from current_date)
  loop
    -- Make an asynchronous HTTP POST request via pg_net without headers
    perform net.http_post(
      url := backend_url,
      body := jsonb_build_object(
        'student_id', student.id,
        'scholar_no', student.scholar_no,
        'name', student.name,
        'department', student.department,
        'fcm_token', student.fcm_token
      )
    );
  end loop;
end;
$$;



