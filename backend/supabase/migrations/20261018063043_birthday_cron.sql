
create extension if not exists pg_cron with schema extensions;



-- Unschedule first so running 'supabase db reset' won't throw duplicate job errors
select cron.unschedule('trigger-birthday-greetings');

select cron.schedule(
  'trigger-birthday-greetings', -- Job name
  '0 8 * * *',                  -- Runs every day at 8:00 AM
  $$select check_student_birthdays();$$
);