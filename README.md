# pcupdater
Proxychains Automate Updater 
# Add to crontab (crontab -e)
```
0 */6 * * * /bin/bash -c "cd ~/pcupdater && nohup ./opoxychains.sh --auto >/dev/null 2>&1 &"```
```

```
0 3 * * * /bin/bash -c "cd ~/pcupdater && nohup ./proxychains_cleanup.sh >/dev/null 2>&1 &"
```
