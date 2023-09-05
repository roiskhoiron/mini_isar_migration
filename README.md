# mini_isar_migration

this is project example isar to migration from another version to target version.

## Getting Started

This project is a starting point for a Flutter application.

Beberapa hal yang perlu dipertimbangkan ketika ingin melakukan migrasi versi local database isar ke versi yang lebih baru:

- [Melakukan perubahan nama field]()
- [Penambahan field harus ditentukan nilainya jika tidak maka akan bernilai NULL]()
- [Perubahan nilai @index(unique: false) menjadi @index(unique: true) harus dilakukan secara manual]()


## Catatan Migrasi versi ke versi

- [Buatlah dokumentasi perubahan yang dilakukan pada database, schema dan atribute serta nilai yang ditentukan juga dirubah]()
- [Gunakan isolate untuk melakukan migrasi database]()
- [Load database dengan pagination jika diperlukan]()

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
