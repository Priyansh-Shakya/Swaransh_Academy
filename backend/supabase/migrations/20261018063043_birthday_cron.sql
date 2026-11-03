create extension if not exists pg_cron with schema extensions;

-- Safely unschedule only if the job exists
do $$
begin
  if exists (select 1 from cron.job where jobname = 'trigger-birthday-greetings') then
    perform cron.unschedule('trigger-birthday-greetings');
  end if;
end;
$$;

-- Schedule the job
select cron.schedule(
  'trigger-birthday-greetings',
  '0 8 * * *',
  $$select check_student_birthdays();$$
);