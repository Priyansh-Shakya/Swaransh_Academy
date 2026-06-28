###

Changes ...

Course Schema will have a title and then importantly , a maps_to_subject , maps_to_department field
so that apply now leadsa to admission form - admission form can pick actual subject rather than title itself.

 I'll add a maps_to_subject (and probably maps_to_department) field to CourseCreate/Course — admin sees two inputs: a free-text display title (what students see, marketing-friendly) and a subject/department picker (constrained to the actual form enums, used purely for pre-fill). 


 So the schema changes needed:

Payment gains: status (active | superseded), superseded_by (nullable FK to the row that replaced it).
PaymentCreate gains: optional paid_on (for backdating manual entries).
New endpoints: PUT /student/{id}/payment/{payment_id} (creates corrected row, marks old one superseded, returns the new row) and DELETE /student/{id}/payment/{payment_id} (genuine hard delete, duplicates only).

One implementation note for when you build this in Postgres, since you've never done supersede-style updates: the cleanest way is usually don't actually implement PUT as an UPDATE at all — under the hood it's just INSERT the new row, then a single UPDATE payments SET status='superseded', superseded_by=<new_id> WHERE id=<old_id>