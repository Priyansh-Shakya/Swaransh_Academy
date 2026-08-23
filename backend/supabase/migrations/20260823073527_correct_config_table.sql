
--* Previous migration added new columsn to config table , but we wanted key value pairs only! , fixing that

ALTER TABLE config 
  DROP COLUMN swaransh_admin_image, 
  DROP COLUMN ravi_admin_image, 
  DROP COLUMN admin_verification_code;


--* Now Inserting them as key-value rows

INSERT INTO config(key , value) VALUES
('swaransh_admin_image' , 'image_path'),
('ravi_admin_image', 'path'),
('admin_verification_code', 'code');

