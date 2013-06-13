Amy installation:
-----------------

Set up database credentials in `amy/conf/amy/configuration.php`.
If using MySQL, also edit `amy/lib/amy/support/mysql.php`

Import _migrations/setup_amy_editor_mysql.php (if using mysql) or _migrations/setup_amy_editor.php (if using postgres).

put the '/amy/trunk' folder in your web server's root. ('trunk' is a remnant from subversion's file structure - you can rename it 'amy')
