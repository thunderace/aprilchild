Amy installation:
-----------------

Set up database credentials in `amy_editor/conf/amy/configuration.php`.
If using MySQL, also edit `amy_editor/lib/amy/support/mysql.php`

Import `amy_editor/_migrations/setup_amy_editor_mysql.sql` (if using mysql) or `amy_editor/_migrations/setup_amy_editor.sql` (if using postgres).

put the '/amy_editor' folder in your web server's root.
