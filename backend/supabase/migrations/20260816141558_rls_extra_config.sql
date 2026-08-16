ALTER TABLE config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read access to config"
ON config
FOR SELECT
TO anon, authenticated
USING (true);