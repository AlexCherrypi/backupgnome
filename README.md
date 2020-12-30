# backupgnome
A little script that can create backups for your Gnome installation and restore them.

My preferred usage: on an USB-Stick, flashed with my favourite Linux ISO. Run the script once before the reinstallation, then again afterwards. No files have to be moved by hand with this process. Everything just works!

`wget https://raw.githubusercontent.com/KnallbertLp/backupgnome/main/backupgnome.sh -O backupgnome.sh && chmod +x backupgnome.sh`

* **Usage:** ./backupgnome [ACTION] [OPTIONS ...]

* **Action:**             	  -b , --backup , --back 	to start backup<br />
                      	-r, --restore , --rest 	to restore backup<br />
                    	  -h , --help             to get this help page<br />

* **Options('-b'&'-r'):** -f [FILE] file to store the backup in and to restore from  (DEFAULT: current directory and file name 'gnomebackup.tar.gz' )<br />
* **Options('-b'):**  -e [DIRECTORY] location to copy the gnome extentions from  (DEFAULT: ~ /.local/share/gnome-shell/extensions/ )<br />
         -d [dconf ~ DIR] directory in dconf. learn more at 'dconf help' or 'man dconf'  (DEFAULT: / )<br />
         -A , -S , -E Backup All the things, only Settings or only Extentions (DEFAULT: -A )
* **Options('-b')(preset):**  -u Preset for very cautious people. <br />            Sets -d dconf directory to '/org/gnome/shell/extensions/'<br />            and -e extention directory to '~/.local/share/gnome-shell/extensions/' <br />

* **Good to know:**		If the script runs without any action specified, it will decide for it self what to do.<br />
        If it finds a 'gnomebackup.tar.gz' in its directory, it will try to load it.<br />
        If it does not find any, it will start creating a new backup <br />
