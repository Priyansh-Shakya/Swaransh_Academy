
    select s.id, s.scholar_no, s.name, s.department, u.fcm_token 
    from students s
    left join users u on s.user_id = u.user_id
    where extract(month from s.dob) = extract(month from current_date)
      and extract(day from s.dob) = extract(day from current_date)