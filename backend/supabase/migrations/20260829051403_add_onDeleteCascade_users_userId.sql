
--* Adding ON DELETE CASCADE on users.user_id

ALTER TABLE public.users
ADD CONSTRAINT del_user_id_on_cascade
FOREIGN KEY (user_id)
REFERENCES auth.users(id)
ON DELETE CASCADE;