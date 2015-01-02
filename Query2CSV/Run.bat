ECHO Query2mail.exe "220.135.140.21" "1521" "HCIP" "HT" "ht-mode"  "select * from TB_HT_BACKUP_RECORD where IN_TIME>(SYSDATE-1) AND IN_TIME<(SYSDATE+1)" "geniustom@gmail.com"

Query2mail.exe "61.218.115.194" "1435" "CallCenter" "sa" "0000"  "select * from Gateway_Data_Process order by date_process" "geniustom@gmail.com;tengchunnan@gmail.com;chrishsutw@yahoo.com" "遠醫備援CTI主機LOG回報"