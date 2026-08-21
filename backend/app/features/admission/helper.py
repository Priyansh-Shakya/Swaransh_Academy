import time


async def _migrate_admission_photo_to_student_bucket(
    admission_image_path: str | None,
    student_token: str,
    storage_client,  # the full Supabase client — has .storage, .table(), etc.
) -> str | None:
    if not admission_image_path:
        return None

    try:
        file_bytes = storage_client.storage.from_("admission-photos").download(admission_image_path)

        ext = admission_image_path.rsplit(".", 1)[-1] if "." in admission_image_path else "jpg"
        ts = int(time.time() * 1000)
        new_path = f"students/{student_token}/{ts}_photo.{ext}"

        storage_client.storage.from_("student-photos").upload(
            new_path, file_bytes, {"content-type": f"image/{ext}"}
        )
        return new_path
    except Exception as e:  # noqa: BLE001
        print(f"[PHOTO MIGRATION NON-BLOCKING ERROR] {e}")
        return None