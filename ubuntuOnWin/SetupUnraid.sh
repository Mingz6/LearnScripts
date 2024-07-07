#  For Unraid system list the full path
root@NAS:~# pwd
/root

#  For Unraid
root@NAS:~# useradd --create-home ming
root@NAS:~# id ming
uid=1007(ming) gid=1007(ming) groups=1007(ming),0(root),3(sys),4(adm),281(docker)
root@NAS:~# passwd ming
New password: 
Retype new password: 
passwd: password updated successfully
root@NAS:~# id root
uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),17(audio),281(docker)
root@NAS:~# usermod -a -G 4,281,3,0 ming
root@NAS:~# id ming
uid=1007(ming) gid=1007(ming) groups=1007(ming),0(root),3(sys),4(adm),281(docker)
root@NAS:~# ls ../home
ming/
root@NAS:~# usermod -s /bin/bash ming
usermod: no changes
root@NAS:~# su ming
ming@NAS:/root$ ls
ls: cannot open directory '.': Permission denied
ming@NAS:/root$ cd ..
ming@NAS:/$ ls
bin  boot  dev  etc  home  hugetlbfs  include  init  lib  lib64  mnt  opt  proc  root  run  sbin  sys  tmp  usr  var
ming@NAS:/$ cd root

# For Vim editor
vim editor
# save and exit
esc :wq
# exit without saving
esc :q!

# Create file
root@NAS:~# vi test.txt
root@NAS:~# ls
dead.letter  test.txt
root@NAS:~# cat test.txt
gjhwqiejeqwje
root@NAS:~# ls
dead.letter  test.txt
root@NAS:~# cat dead.letter