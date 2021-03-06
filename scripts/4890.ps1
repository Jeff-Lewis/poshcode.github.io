# Written by John Brearley, Fall 2013
# email: brearley@bell.net
# email: jrbrearley4@gmail.com

# License: This script is free to use, modify and/or redistribute,
# however you MUST leave the author credit information above as is
# and intact.

# Support: Available on a best effort basis.

# Acknowlegement: Thanks to CompuCorps.org for the loan of a PC 
# with MS Office 2013 and for beta testing.


# For online help, in a powershell window, type: test-apps.ps1 -h


#==================== script run control file =====================
# This script supports an optional run control file called
# test-apps-rc.ps1. If this file is found, it will be executed so 
# that different settings can be used on selected PC as specified 
# in the run control file.
#
# For example, some PC may not have MS Office installed, and you
# want the MS Office tests to be skipped. You can also specify 
# different try counts, iteration counts, colors, etc in the run
# control file. Everything in the User Defined Variables section
# just below here is fair game. 
#
# NB: While you probably could manipulate other variables elsewhere
# in the script, please DONT!
#==================================================================


#==================== User Defined Variables ======================
# User may need to update these variables depending on local
# configuration & preferences. 
#==================================================================

# When the tests are completed, the results files will be copied to 
# the server directory defined below. Put your own value here or in
# the run control file discussed above, and uncomment the line.
# $script:server_results_dir = "\\192.168.0.100\test_results"

# WinXP & Linux servers will allow you to define shared R/W directories
# that are accessible by all users without any username/password
# challenge. If you are using a server that requires authentication
# before you can access the desired results directory, then put the
# required domain\user and password info here, or in the run control
# file discussed above, and uncomment these lines.
# $script:server_username = "user" # you main need to put: domain\username
# $script:server_password = "password"

# Number of times a test case will be tried before being considered
# a test case failure. Can be dynamically modified via command line
# option: -try N
$script:testcase_try_max = 3  # minimum 1

# Number of times to run all the test cases. Can be dynamically 
# modified via command line option: -iter M
$script:testsuite_interation_max = 1  # minimum 1

# The tests to be run (or not run) can be chosen by the groupings
# shown below. There are command line options to dynamically control
# all these options. The value should be $true or $false
$script:test_batt = $true           # Laptop battery test, user MUST unplug/replug AC power
$script:test_config = $true         # CPU, RAM, HDD, Windows activation, missing driver tests
$script:test_ms_office = $true      # MS Office tests
$script:test_ms_sec_cl = $true      # MS Security Client test
$script:test_network = $true        # ping, clock sync, web browsers (Chrome, Firefox, IE) tests
$script:test_open_office = $true    # Open Office tests
$script:test_other = $true          # notepad, wordpad, screenshot tests

# If you want to run only a specific list of test cases, put your own list
# here or in the run control file discussed above, and uncomment the line.
# $script:tc_list = "tc_4 tc_6 tc_7"

# Minimum amount of RAM (Random Access Memory), in GB, that must be installed.
$script:ram_minimum_gb = 2 # in GB 

# Minimum number of CPU (or threads) that must be installed. This is helpful
# in weeding out the really old low power CPU PC.
$script:cpu_minimum = 2

# Minimum amount of HDD (Hard Disk Drive), in GB, that must be installed.
# Multiple HDD will be totaled up to check the minimum requirement.
# NB: The value here should be the software view of a GB, namely 1024 * 1024 * 1024,
# not the hardware view of a GB, namely 1000 * 1000 * 1000.
# NB: A hardware 80 GB disk will be only 74 GB from software point of view.
$script:hdd_minimum_gb = 74 # in GB 

# Web site used for ping tests.
$script:ping_host = "google.ca"

# Number of pings that the ping test will do.
$script:ping_cnt = 5

# Percentage of pings that must succeed for the ping test to be considered a pass.
$script:ping_pass_percent = 60 # %, range 1 - 100

# WIFI network links may need several cycles of sacrificial pings to 
# initially warmup and get going properly under adverse RSSI conditions.
# In each warmup cycle, $script:ping_cnt pings will be done to see what
# shape the WIFI link is in. If the pings all fail, another warmup cycle
# will be done. These tests continue until the WIFI link is working 
# properly, or we hit the maximum number of warmup cycles, below. 
$script:wifi_warmup_cycles_max = 5

# Web site used for browser tests.
$script:web_host = "webcrawler.com"

# Pattern used to validate page contents for above web_host.
$script:web_page_pattern = "title.*webcrawler.*web.*searchtitle"

# To test MS Outlook, the preferred way is to have a dummy email server
# available with a valid email address & password that can be used
# by this script. For a dummy email server, I use the free hMailServer
# from: http://www.hmailserver.com/index.php?page=download
#
# The dummy email server is expected to become a permanent part
# of the place you are testing PC apps. You could run the hMailServer
# on your own desktop PC, or you could run it on a separate PC
# dedicated just for this task.
#
# After you run the setup.exe file, all you need to do is configure
# a Domain name and one email Account, as described below:
#
# 1) On the hMailServer administrator window, click on the Domains
#    icon. Now you can type in the desired Domain name & save it.
#    The suggested domain name is: xyz123abc.ca
#
# 2) Now click on the "+" sign beside the Domain icon to expand it.
#    Now click on the "+" sign for the domain name you just created
#    to expand it.
#
# 3) On the Accounts folder icon, right click and choose Add...
#    Now you can type in the new email address, password and save it.
#    The suggested email address is: webmaster
#    The suggested password is: 1234abcd
#
# 4) Thats it, you are done!
#
# This takes all of 5 minutes for a novice user to set up hMailServer.
#
# NB: If Windows Firewall is active, it will block incoming mail 
# connections from other PC, causing the test case to fail. So, you
# will need to tell Windows Firewall to allow traffic on ports 
# 25 & 110. If you are running other anti-virus software, you could
# just turn off Windows Firewall completely.
#
# NB: DONT use a real corporate email server for this test!!!
# If you do, then you need to worry about people finding the 
# username and password in this script (or the run control file)
# and possibly abusing this email account, which is definitely
# NOT a desired outcome! So use the dummy email server described
# above or dont run the Outlook test.
#
# Define info for setting up email account to use with dummy email server.
$script:email_display = "Web Master"
$script:email_address = "webmaster@xyz123abc.ca"
$script:email_password = "1234abcd"
$script:email_needs_authentication = $true
$script:email_server_name = "mail.xyz123abc.ca"
# $script:email_server_ip = "192.168.0.100"
#
# NB: The MS Outlook test case tc_15 will not run without the email
# server ip address information. Once you have setup the dummy
# email server, put your own valu here and uncomment the line above,
# or put a line in the run control file discussed above,
#
# NB: The above email server name & IP are used to create a
# mapping in the local PC hosts file so that it can find the
# dummy email server on your local area network. You dont 
# need to worry about your DNS server knowing how to find
# the dummy email server. The dummy email server PC networking
# software does not even need to be given any knowledge of the
# domain name being used for email purposes. 
#
# On occasion, the email server may be running slowly, and the
# test email that the script sends is NOT received the first
# time the script does "F9" to get the new email. The option
# below lets you specify how many times the script will do "F9"
# to get new email.
$script:email_get_mail_cnt = 1

# Define allowable age, in hours, for Microsoft Security Client
# virus & scans. The virus definition age & most recent scan age
# must be less or equal to this value for the test to pass.
$script:ms_sec_age = 24 # in hours

# Define the lower battery life threshold for running the battery discharge
# test. If the PC battery life is less than this value, the battery discharge
# test will not be run. Its possible that the battery may not be fully
# charged, or if it is fully charged, that the battery is old and lost a lot
# of its original capacity. In either case, we dont want to run the battery
# discharge test, as there may not be enough battery life to complete the
# test.
$script:battery_life_threshold = 30 # %, range 1 - 100

# Define how long the battery test must discharge the battery, in minutes,
# in order to get a credible estimate of the battery life.
$script:battery_test_discharge_min = 7 # minutes

# Define the expected minimum battery life, in minutes, for the battery
# discharge test to be considered a PASS.
$script:battery_life_pass_min = 45 # minutes

# Alternate directory to find wasp.dll, in case it is not in the
# current working directory.
$script:wasp_dir="c:\wasp"

# Preferred web browser for displaying test case results page.
# Chrome, Firefox & IE all work OK.
$script:browser_results = "firefox"

# If you dont want the test case results automatically displayed
# in the preferred web browser, then uncomment the line below, or 
# add a line in the run control file discussed above.
# $script:nobr = $true

# Colors to be used in test case results page.
$script:color_background = "white"    # page backgound color
$script:color_info = "blue"           # normal, basic text color
$script:color_bold = "cadetblue"      # bold text color
$script:color_warning = "gold"        # warning text color
$script:color_error = "magenta"       # error text color
$script:color_fatal = "purple"        # fatal error text color
$script:color_tc_pending = "orange"   # test case pending result text color
$script:color_tc_fail = "red"         # test case fail result text color
$script:color_tc_pass = "green"       # test case pass result text color
$script:color_tc_skip = "brown"       # test case skipped text color
$script:color_iteration = "lime"      # test iteration page marker text color

# Size for individual window screenshots on test results html page.
# This ensures the individual screenshots fit into the available
# viewing space on ther results page.
$script:screenshot_window_width =  400  # in pixels
$script:screenshot_window_height = 300  # in pixels

# Scale factor for full desktop screenshots on test results html page.
# This ensures the full desktop screenshots fit into the available
# viewing space on the results page.
$script:screenshot_full_scale_factor = 0.5   # range is 0 to 1

# Define windows to ignore.
# I often have the CBC Radio running in the background.
$script:ignore_list = "CBC.*RADIO"


#==================== End of User Options =========================
# Dont change anything below here!!!
# Unless you are a Powershell expert!!! Or are planning to be one!!!
#==================================================================


#==================== Powershell Notes ============================
# Major powershell learning points here!!! 
#==================================================================
# Powershell uses the backtick as an escape, not the backslash!
# You get parsing errors if you try \"

# When a function returns, any stdout messages are returned as part
# of the results array. Being able to have debug info sent to the
# terminal window is a fundamental debugging technique. To extract
# the result at the end of all the debug messages, use:
# $result = myfunc $p1 $p2 $p3
# $rc=$($result[$result.count-1])
# The other approach is to use script level variables to pass
# selected results from the function to the calling routine.
# This avoids having to filter out the debug messages.

# While powershell itself seems able to set the return status $?,
# the powershell user community does not seem to be able to 
# figure out how to do that from within a function or cmdlet.

# Watch out for the .count method. In many places, it will return
# null value when there is 0 or 1 item. It will correctly return
# correct count for 2 or more items. It will also count null items.
# In places where you need accurate count of non-null items, you
# need to do your own testing of data and counting.


#==================== Common Functions ============================
# Common routines used in this script.
#==================================================================


#==================== add_file_content ============================
# Adds value string to the specified path. Provides error handing
# and a backoff / retry algorithm when errors writing to a file occur.
#
# Under load with larger log files, you get occasionlly errors about
# object in use by another process, such as firefox. Backing off and
# trying again usually allows the situation to recover.
#
# Calling parameters: path, value
# There are 2 logfiles, so we do need to be able to specify the path
#
# Returns: null or exits script on unrecoverable error
# Sets variables: $script:add_content_issue, $script:add_content_max_delay
#==================================================================
function add_file_content ($path="", $value="") {

   # There can be cases where the logfile is not yet initialized, 
   # so we add these messages to the queue for logging later on.
   # "add_file_content path=$path value=$value"
   if ($path -eq "") {
      $script:msg_q += $value
      return
   }

   # Define delays to use in backoff / retry algorithm, in milli-seconds
   # First delay is 0, so that the normal case logging is not impacted.
   $delay_array = 0, 100, 200, 500, 1000, 2000, 5000, 10000, 15000, 30000, 60000, 120000, 180000, 240000, 300000, 300000, 300000, 300000, 300000, 300000, 300000, 300000, 300000, 300000 # milliseconds

   # Try repeatedly to add content to file.
   $error_list = "" # keep track of all errors encountered, used when we DONT recover.
   $last_error = "" # keep track of last error, used when we recover OK.
   foreach ($delay in $delay_array) {

      # Wait before adding content.
      # "add_file_content delay=$delay"
      start-sleep -m $delay

      # Try to add content to file.
      $err = ""
      $pm = ""
      $saved_rc = $False
      try {
         add-content -path "$path" -value "$value"
         $saved_rc = $?
      } catch {
         $x = $Error | select-object -first 1 # Never seem to get error text, even though it is available at command prompt
         $err = $x.tostring()
         $pm = $x.invocationinfo.positionmessage # Shows which line in script got the error!!!
         $err = "$err $pm"
         $saved_rc = $False
      }

      # Test code to cause retries.
      # NB: This will cause a message to show up repeatedly in the logfile.
      # NB: For retries during finalize_logfile, this can cause the tc stats
      #     table to show up repeatedly! This was a very interesting side effect!
      # if ($script:add_content_issue -eq 0 -and $delay -lt 200) {
      #     $saved_rc = $false
      #     $err = "faking error..."
      #     "`n`n++++++++ add_file_content faking error for path=$path delay=$delay err=$err value=$value`n`n"
      # }

      # If we succeeded, exit loop.
      if ($saved_rc) {
         break

      } else {
         # Accumulate all errors.
         $error_list = "${error_list}delay=$delay saved_rc=$saved_rc err=$err`n"
         # "delay=$delay err=$err"
         if ($err -ne "") {
            $last_error = "delay=$delay saved_rc=$saved_rc err=$err"
         }
      }
   }

   # Look for errors.
   # "add_file_content saved_rc=$saved_rc"
   if ($saved_rc) {
      # We succeeded, but did we have to retry?
      if ($delay -gt 0) {
         $script:add_content_issue++
         if ($delay -gt $script:add_content_max_delay) {
            $script:add_content_max_delay = $delay
         }
         # Since we have recovered from the transient error, it SHOULD
         # be safe to log a warning about what just happened.
         # We show only the last delay & error to avoid log clutter.
         log_debug "add_file_content succeeded on delay=$delay last_error: $last_error"
         return
      }

   } else {
      # All logging retries have failed. Its game over!
      # We can always put the errors on the terminal window.
      "`nFATAL ERROR: add_file_content path=$path `nvalue=$value `nerror_list:`n$error_list`n"
      exit 1
   }
}


#==================== add_horizontal_rule =========================
# Adds a horizontal rule and surrounding whitespace to the logfile.
#
# Calling parameters: none
# Returns: null
#==================================================================
function add_horizontal_rule {

   # Add horizontal rule tags to logfile.
   log_msg "`n`n`n<br><hr color=`"$script:color_info`">"
}


#==================== add_html_header =============================
# Adds starting html tags to the logfile.
#
# Calling parameters: filepath
# Returns: null
#==================================================================
function add_html_header ($filepath) {

   # Add HTML header tags to logfile.
   $msg = ""
   $saved_rc = $False
   try {
      # NB: We dont dont use the add_file_content routine here while
      # trying to initialize the file. If this fails, its game over.
      add-content -path "$filepath" -value "<!DOCTYPE html>"
      add-content -path "$filepath" -value "<HTML>"
      add-content -path "$filepath" -value "<HEAD>"
      add-content -path "$filepath" -value "   <TITLE>$script:log_suffix</TITLE>"
      add-content -path "$filepath" -value "</HEAD>"
      add-content -path "$filepath" -value " "
      add-content -path "$filepath" -value "<BODY bgcolor=`"$script:color_background`">"
      add-content -path "$filepath" -value " "
      $saved_rc = $?
   } catch {
      $msg = $Error | select-object -first 1
      $saved_rc = $False
   }
   # "saved_rc=$saved_rc"

   # Check for errors.
   if(!$saved_rc) {
      log_fatal_error "add_html_header got: $msg"
   }
}


#==================== add_html_trailer ============================
# Adds ending html tags to the logfile.
#
# Calling parameters: filepath
# Returns: null
#==================================================================
function add_html_trailer ($filepath) {

   # Add HTML trailer tags to the logfile.
   $msg = ""
   $saved_rc = $False
   try {
      # NB: We dont dont use the add_file_content routine here while
      # trying to initialize the file. If this fails, its game over.
      add-content -path "$filepath" -value ""
      add-content -path "$filepath" -value "</BODY>"
      add-content -path "$filepath" -value "</HTML>"
      $saved_rc = $?
   } catch {
      $msg = $Error | select-object -first 1
      $saved_rc = $False
   }
   # "saved_rc=$saved_rc"

   # Check for errors.
   if(!$saved_rc) {
      log_fatal_error "add_html_trailer got: $msg"
   }
}


#==================== check_email_routing =========================
# Checks local PC host file for route entry for dummy email server,
# adds entry if needed.
#
# Calling parameters: none
# Returns: null
#==================================================================
function check_email_routing {

   # Define path to local PC host file.
   $hosts_file = "$env:SystemRoot\system32\drivers\etc\hosts"
   # log_debug "check_email_routing hosts_file=$hosts_file"

   # Read hosts file.
   get_file_contents $hosts_file "" -nolog

   # Check if the hosts file already has email server name & IP.
   $patt = "${script:email_server_ip}\s+${script:email_server_name}"
   # "patt=$patt"
   foreach ($l in $script:file_contents) {
      # "l=$l"
      if ($l -match "$patt") {
         log_info "check_email_routing patt=$patt MATCH l=$l"
         return
      }
   }

   # Add routing entry for email server.
   log_bold "check_email_routing adding routing entry to: $hosts_file"
   $msg = ""
   $saved_rc = $false
   try {
      add-content -path "$hosts_file" -value "$script:email_server_ip   $script:email_server_name `n`n"
      $saved_rc = $?
   } catch {
      $saved_rc = $false
   }

   # Check for errors.
   # "saved_rc=$saved_rc"
   if (!$saved_rc) {
      $msg = $error | select-object -first 1
      throw_error "NB: You MUST run as administrator to update ${hosts_file}, msg=$msg"
   }
}


#==================== clear_nav_bar ===============================
# Looks for browser navigation bar control and clicks on it and
# clears the text.
#
# NB: Only IE has controls to access nav bar. 
#
# Calling parameters: hnd
# Returns: null
#==================================================================
function clear_nav_bar ($hnd="") {

   # Sanity check.
   if (!$hnd -or $hnd -eq "" -or $hnd -eq 0) {
      log_error "clear_nav_bar invalid hnd=$hnd"
      return
   }

   # Get controls for specified window.
   log_info "clear_nav_bar hnd=$hnd"
   get_window_obj $hnd
   get_controls $script:curr_obj
   
   # Look for exact match for the navigation bar control.
   # NB: We are trying to avoid the Live Search bar control.
   search_controls "edit" "^(about|file|http|www)" 1 -quiet
   # $script:ctl_hnd = "" # test code
   if (!$script:ctl_hnd) {

      # Exact match failed, try first loose match.
      # log_info "clear_nav_bar trying loose match (1) hnd=$hnd"
      search_controls "" "about|file|http|www" 1 -quiet
      # $script:ctl_hnd = "" # test code
      if (!$script:ctl_hnd) {

         # First loose match failed, try second loose match, with -nottitle option.
         # log_info "clear_nav_bar trying loose match (2) hnd=$hnd"
         search_controls "edit" "live" 1 -nottitle -warnonly # want control data if not found
         # $script:ctl_hnd = "" # test code
         if (!$script:ctl_hnd) {

            # Control not found, we are done.
            log_error "clear_nav_bar: (3) hnd=$hnd, no loose match for navigation bar control!"
            return
         }
      }
   }

   # Click on the control.
   send_click $script:ctl_hnd
         
   # Clear the text with Ctrl-A Backspace.
   start-sleep -m 500
   send_keys $script:ctl_hnd "^a{backspace}"

   # Again to make it more reliable.
   start-sleep -m 500
   send_keys $script:ctl_hnd "^a{backspace}"
}


#==================== close_child_windows ==========================
# Looks for any child window or related modal windows and if found,
# closes them all. If hnd is not specified, then we try to close all
# child or modal windows based on the specified app_name.
#
# Calling parameters: hnd app_name
# NB: If hnd is specified, app_name will be retrieved based on hnd.
#
# Returns: null
# Sets variables: $script:curr_obj
#==================================================================
function close_child_windows ($hnd="",$app_name="") {

   # NB: Unfortuneately, the Firefox "Default Browser" dialog box
   # is not detectable as a separate window, child window or
   # control. So we cant deal with it yet...

   # NB: IE really gets unhappy if you minimize the appl & modal
   # windows. So call close_child_windows before doing a restore_window.

   # Sanity check
   if (!$hnd -and !$app_name) {
      log_error "close_child_windows both parameters invalid: hnd=$hnd app_name=$app_name"
      return
   }

   # Find the current window object based on hnd, get app_name.
   $script:curr_obj = ""
   if ($hnd) {
      # This makes sure that hnd takes precedance and we use the
      # correct app_name for the specified handle.
      get_window_obj $hnd
      $app_name = $script:curr_obj.processname
      # log_info "close_child_windows hnd=$hnd curr_obj=$script:curr_obj"
   } else {
      # Use the specified app_name, as is.
   }
   # log_info "close_child_windows hnd=$hnd app_name=$app_name"

   # Both Firefox & IE allow one SaveAs window open per main window,
   # so be careful here.

   # New versions of IE sometimes pop up a modal window and other
   # times will pop up a child window. It seems to always be one
   # way on a specific PC, but can vary from PC to PC.
   # The fun part here is that you could have multiple IE windows
   # active, or other apps that do modal windows, each with its own
   # modal SaveAs window. They all have different pids, which could
   # be matched up using wmic process. For now, we match on the app
   # name for a slightly better, but still imperfect result.

   # In case of misbehaved apps, we try multiple times to close 
   # child or associated modal windows. Most of the time, there
   # is no child window or modal window.
   $total_closed = 0
   $type = ""
   for ($i = 1; $i -le $script:max_loop; $i++) {

      # Look for a child window or modal windows.
      $ch = ""
      $closed = 0 # counters for this iteration
      $found = 0
      if ($app_name -match "iexplore" -and $script:ie_major_ver -gt 8) {
         $ch = select-window -class *modal* # cant specify 2 search parameters at once!
         $cnt = $ch.count
         $type = "modal"
         # "modal: i=$i cnt=$cnt ch = $ch"
         foreach ($w in $ch) {
            # Decode window object
            $c = $w.Class
            $h = $w.Handle
            $n = $w.ProcessName
            $t = $w.Title
            # "close_child_windows i=$i modal c=$c h=$h n=$n t=$t"
            if (!$h) {
               continue
            }

            # Close the modal windows that match app_name
            if ($n -match $app_name) {
               # "MATCHED app_name=$app_name"
               $found++
               log_info "close_child_windows i=$i hnd=$hnd app_name=$app_name closing $type window, c=$c h=$h n=$n t=$t"
               remove_window $w -warnonly
               if ($script:remove_window_rc) {
                  $closed++
                  $total_closed++
               }

            } else {
               log_debug "close_child_windows i=$i hnd=$hnd app_name=$app_name ignoring $type window, c=$c h=$h n=$n t=$t"
            }
         }

         # If we closed everything relevant for this iteration, we are done.
         # NB: Dont break here unless we really closed a window! Otherwise
         # we wont check for child windows!
         # "modal: i=$i found=$found closed=$closed"
         if ($found -eq $closed -and $closed -gt 0) {
            # "modal: i=$i break"
            break
         }
      }

      # If no modal windows found, look for child windows.
      if (!$ch) {
         if ($hnd) {
            # Handle was specified, just look at this single window.
            $ch = select-childwindow -window $hnd
         } else {
            # No handle was specified, so look at all windows for this app_name.
            map_app_name $app_name
            $ch = select-window -title "*$script:app_title*" | select-childwindow
         }
         $cnt = $ch.count
         $type = "child"
         # "child: i=$i cnt=$cnt ch=$ch"
         foreach ($w in $ch) {
            # Decode window object.
            $c = $w.Class
            $h = $w.Handle
            $n = $w.ProcessName
            $t = $w.Title
            if (!$h) {
               continue
            }

            # Close the child window.
            $found++
            log_info "close_child_windows i=$i hnd=$hnd app_name=$app_name closing $type window, c=$c h=$h n=$n t=$t"
            remove_window $w -warnonly
            if ($script:remove_window_rc) {
               $closed++
               $total_closed++
            }
         }

         # If we closed everything relevant for this iteration, we are done.
         # "child: i=$i found=$found closed=$closed"
         if ($found -eq $closed) {
            # "child: i=$i break"
            break
         }
      }

      # Wait a bit
      if ($i -lt $script:max_loop) {
         # "i=$i waiting..."
         start-sleep -s 1
      }
   } 

   # Check what really happened.
   # log_info "close_child_windows i=$i type=$type closed=$closed found=$found total_closed=$total_closed"
   if ($closed -ne $found  -or $i -gt $script:max_loop) {
      log_error "close_child_windows hnd=$hnd app_name=$app_name tried $script:max_loop times to close $type window(s), FAILED, still open: $ch"

   } elseif ($i -eq 1 -and $found -eq 0) {
      # Nothing found on first try, which is the usual case.
      log_info "close_child_windows hnd=$hnd app_name=$app_name no $type windows found OK, Try#: $i"

   } elseif ($i -eq 1 -and $found -gt 0) {
      # Succeeded on first try.
      log_info "close_child_windows hnd=$hnd app_name=$app_name found $total_closed $type window(s), closed OK, Try#: $i"

   } else {
      log_warning "close_child_windows hnd=$hnd app_name=$app_name found $total_closed $type window(s), closed OK, Try#: $i"
   }
}


#==================== close_windows ===============================
# Looks for any windows with the specified app_name and if found,
# closes them all. 
#
# Calling parameters: app_name
# Returns: null
#==================================================================
function close_windows ($app_name="") {

   # Sanity check
   if (!$app_name) {
      log_error "close_windows invalid: app_name=$app_name"
      return
   }

   # Try multiple times to close app_name windows.
   $total_closed = 0
   for ($i = 1; $i -le $script:max_loop; $i++) {

      # Look for app_name windows.
      $ch = ""
      $closed = 0 # counters for this iteration
      $found = 0
      map_app_name $app_name
      $w_list = select-window -title *$script:app_title*
      $cnt = $w_list.count
      # "i=$i cnt=$cnt w_list=$w_list"
      foreach ($w in $w_list) {
         # Decode window object
         $c = $w.Class
         $h = $w.Handle
         $n = $w.ProcessName
         $t = $w.Title
         # "close_windows i=$i c=$c h=$h n=$n t=$t"
         if (!$h) {
            continue
         }

         # Close this window
         $found++
         remove_window $w -warnonly
         if ($script:remove_window_rc) {
            $closed++
            $total_closed++
         }
      }

      # If we closed everything relevant for this iteration, we are done.
      # "close_windows i=$i found=$found closed=$closed"
      if ($found -eq $closed) {
         # "i=$i break"
         break
      }
   }

   # Check what really happened.
   # log_info "close_windows i=$i closed=$closed found=$found total_closed=$total_closed"
   if ($closed -ne $found  -or $i -gt $script:max_loop) {
      log_error "close_windows app_name=$app_name tried $script:max_loop times to close window(s), FAILED, still open: $w_list"

   } elseif ($i -eq 1 -and $found -eq 0) {
      # Nothing found on first try, which is the usual case.
      log_info "close_windows app_name=$app_name no windows found OK, Try#: $i"

   } elseif ($i -eq 1 -and $found -gt 0) {
      # Succeeded on first try.
      log_info "close_windows app_name=$app_name found $total_closed window(s), closed OK, Try#: $i"

   } else {
      log_warning "close_windows app_name=$app_name found $total_closed window(s), closed OK, Try#: $i"
   }
}


#==================== copy_file ===================================
# Copies src file path to dest file path. Will not overwrite an
# existing file, except for the <hostname>_latest.html file.
#
# Calling parameters: src dest
# Returns: null
# Sets variables: $script:copy_file_rc
#==================================================================
function copy_file ($src="", $dest="") {

   # Does the destination file already exist? Dont overwrite!
   $script:copy_file_rc = $false
   "copy_file src=$src dest=$dest" # show on terminal window as progress indicator.
   if (!($dest -match $script:latest_fn) -and (test-path "$dest")) {
      log_error "copy_file dest=$dest already exists, will NOT overwrite!"
      return
   }

   # Try multiple times to copy the file.
   for ($i = 1; $i -le $script:max_loop; $i++) {
      $msg = ""
      $saved_rc = $false
      try {
         copy-item -path "$src" -destination "$dest"
         $saved_rc = $?
      } catch {
         $msg = $Error | select-object -first 1
         $saved_rc = $false
      }

      # Test code
      # if ($i -le 1) {
      #    $msg = "yadee"
      #    $saved_rc = $false
      # }

      # If we succeeded, we are done.
      if ($saved_rc) {
         $script:copy_file_rc = $true
         # "copy_file i=$i OK $src"
         return
      }

      # Wait a bit before trying again.
      # "saved_rc=$saved_rc"
      log_warning "copy_file i=$i src=$src got: $msg"
      if ($i -lt $script:max_loop) {
         # "copy_file i=$i waiting..."
         start-sleep -s 10
      }
   }

   # We failed!
   log_error "copy_file tried $script:max_loop times src=$src dest=$dest got: $msg"
}


#==================== copy_results_to_server ======================
# Copies all files created during tests to the specified server
# results subdirectory. 
#
# Calling parameters: none
# Returns: null
#==================================================================
function copy_results_to_server {

   # Are we supposed to copy the test results to a central server?
   if ($script:nocs -or !$script:test_network -or !$script:server_results_subdir -or $script:server_results_subdir -eq "") {
      log_warning "copy_results_to_server files NOT copied to central server, nocs=$script:nocs test_network=$script:test_network server_results_subdir=$script:server_results_subdir"
      return
   }

   # Expected result files are: screenshots + fullreport + summary + <hostname>_latest.html
   $result_file_cnt = $script:total_screenshot + 3

   # For multiple iterations, add message to logfile, which shows timestamp.
   if ($script:testsuite_interation -ne 1) {
      log_info "copy_results_to_server starting copy of $result_file_cnt files..."
   }

   # Get list of results files.
   # NB: The dir command gives us the full pathname even if we
   # didnt explicitly ask for it.
   $files = dir "${pwd}\${script:logname}*"
   # "files=$files"     

   # Copy files to central server, except for fullreport.
   $copied = 0
   $found = 0 
   $full_report = ""
   foreach ($src in $files) {

      # Extract just the filename for use in destination pathname.
      $f = [System.IO.Path]::GetFileName($src)
      # "src=$src f=$f"

      # We defer copying this file to the very end.
      if ($src -match "fullreport") {
         $full_report = $src
         # log_info "defer copying full_report=$full_report"
         continue
      }
      
      # Copy the file to the server results directory.
      $found++
      copy_file "$src" "$script:server_results_subdir\$f"
      if ($script:copy_file_rc) {
         $copied++
      }
   }

   # Now copy the <hostname>_latest.html file
   $found++
   copy_file "$pwd\$script:latest_fn" "$script:server_results_subdir\$script:latest_fn"
   if ($script:copy_file_rc) {
      $copied++
   }

   # Leaving the fullreport to the very end allows copy errors to
   # to be appended to the report. Admittedly the summart stats
   # tables will not include these errors. 
   $found++
   $f = [System.IO.Path]::GetFileName($full_report)
   copy_file "$full_report" "$script:server_results_subdir\$f"
   if ($script:copy_file_rc) {
      $copied++
   }

   # Did we find the correct number of files?
   log_info "copy_results_to_server result_file_cnt=$result_file_cnt found=$found copied=$copied server_results_dir=$script:server_results_dir"
   if ($result_file_cnt -ne $found) {
      log_error "copy_results_to_server result_file_cnt=$result_file_cnt NE found=$found server_results_dir=$script:server_results_dir"
   }

   # NB: If you are checking files on the server against the local PC,
   # there is one more file on the server besides the ones we just copied,
   # namely the .res file created to reserve this logname at the start
   # of the tests.
}


#==================== date_time_sync ==============================
# Syncs up the date/time from the network, stores the results for 
# use later by tc_2 when a logfile is available.
#
# Calling parameters: none
# Returns: null
# Sets variables: $script:date_time_sync_rc, $script:date_time_sync_txt
#                 $script:date_time_sync_jpg
#==================================================================
function date_time_sync {

   # If the network tests are not being run, then quietly return.
   if (!$script:test_network) {
      return
   }

   # If tc_2 is not in the list of tests to run, then quietly return.
   # This avoids extra delays when debugging other code. We DONT need
   # to waste time running unnecessary date/time syncs from the network
   # every time the script runs.
   # "date_time_sync tc_list=$script:tc_list"
   $found = $false
   foreach ($tc in $script:tc_list) {
      # "tc=$tc"
      if ($tc -eq "tc_2") {
         # "FOUND: $tc"
         $found = $true
         break
      }
   }
   if (!$found) {
      # "date_time_sync not running"
      return
   }

   # Initialization
   $script:date_time_sync_rc = ""
   $script:date_time_sync_txt = ""
   $script:date_time_sync_jpg = ""
   log_info "date_time_sync starting"

   # For WinXP, the Date/Time control panel does not show up with
   # its own window object or handle. So we use the command line
   # w32tm.exe to force a network time sync.
   if ($script:win_major_ver -le 5) {
      # Run the command. Command does not return output until its done.
      $script:date_time_sync_txt = w32tm.exe /resync

      # Parse the stdout
      if ($script:date_time_sync_txt -match "complete.*success") {
         $script:date_time_sync_rc = $true
      } else {
         $script:date_time_sync_rc = $false
      }

      # There is nothing to take a screenshot of here.
      $script:date_time_sync_jpg = ""
      log_info "date_time_sync done"
      return
   }

   # For WinVista, Win7 onwards we start the Windows Date & Time control panel.
   # We dont use start_app because this process shows up as rundll32 & title=date & time.
   $msg = ""
   $saved_rc = $False
   try {
      start-process -filepath "control.exe" -argumentlist "timedate.cpl" -erroraction silentlycontinue
      $saved_rc = $?
   } catch {
      $msg = $Error | select-object -first 1
      $saved_rc = $False
   }

   # Check for errors
   if (!$saved_rc) {
      log_error "date_time_sync got: $msg"
   }

   # Find handle, get window object, focus window.
   start-sleep -s 2
   resolve_window_handle "Date"
   $date_hnd = $script:curr_hnd
   restore_window $date_hnd
   # log_info "date_time_sync date_hnd=$date_hnd"
   get_window_obj $date_hnd
   $date_obj = $script:curr_obj

   # Use tabs to select control panel top tab area.
   # Number of tab keys to send depends on windows version.
   if ($script:win_major_ver -eq 6 -and $script:win_minor_ver -eq 0) {
      # WinVista
      $tab_cmd = "{tab}{tab}{tab}{tab}{tab}{tab}"
   } else {
      # Win7 onwards.
      $tab_cmd = "{tab}{tab}{tab}{tab}{tab}{tab}{tab}"
   }
   start-sleep -s 1
   send_keys $date_hnd $tab_cmd

   # Select the right most tab via ctrl-rightarrow.
   send_keys $date_hnd "^{right}^{right}"

   # Look for Change Settings button & click it.
   start-sleep -s 1
   get_controls $date_obj
   search_controls "button" "Change.*Setting" 1
   send_click $script:ctl_hnd

   # Look for Update Now button and click it.
   start-sleep -s 1
   get_controls $date_obj -childonly
   search_controls "button" "Update.*Now" 1
   send_click $script:ctl_hnd

   # Wait for successfull synchronization msg.
   # NB: We ask for -childonly controls because the main window
   # has the most recent update status, which we dont want!!!
   # We want the latest status, which will be on the child window!!!
   wait_for_control $date_obj 30 "success.*sync" "error.*occur" -childonly
   $script:date_time_sync_rc = $script:wait_for_control_rc
   $script:date_time_sync_txt = $script:ctl_title
   # "date_time_sync_rc=$script:date_time_sync_rc date_time_sync_txt=$script:date_time_sync_txt"

   # Take screenshot with child window still open and cache it for use later.
   # NB: The first time the screenshot is taken, the script:logname will be null,
   # so the screenshot filename will be just tc_2_1.jpg. Later on, tc_2 has code
   # to rename the file and properly link it into the results logfile.
   get_screenshot "tc_2" "fg" "Internet.*Time"
   $script:date_time_sync_jpg = $script:scr_fn
   # "date_time_sync_jpg=$script:date_time_sync_jpg"

   # Click OK on child window.
   start-sleep -s 1
   get_controls $date_obj -childonly
   search_controls "button" "OK" 1
   send_click $script:ctl_hnd
   start-sleep -s 1

   # Click OK on main window.
   get_controls $date_obj
   search_controls "button" "OK" 1
   send_click $script:ctl_hnd
   start-sleep -s 2
   log_info "date_time_sync done"

   # NB: tc_2 will make PASS/FAIL decisions.
}


#==================== delete_email_profile ========================
# Deletes the email profile added by setup_ms_outlook.
#
# Calling parameters: none
# Returns: null
#==================================================================
function delete_email_profile {

   # MS Outlook installs its own control panel for managing the
   # email profiles, called MLCFG32.CPL. The location of this 
   # custom control panel is found in the registry at:
   # HKEY_CURRENT_USER\Control Panel\MMCPL or 
   # HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Current Version\Control Panel\Cpls

   # Right now this code is not implemented. My concern is that 
   # even if I put an option run/not run this routine, someone
   # will run this on their production PC and trash their real
   # Outlook profile. While the .PST file will not get deleted,
   # all the other email server settings will be gone.

}


#==================== estimate_battery_life =======================
# Estimate the battery life from the data in $script:batt_array.
#
# Calling parameters: null
# Returns: null
# Sets variables: $script:batt_est_time_min
#==================================================================
function estimate_battery_life {

   # NB: The battery discharge data may have more than one cycle of
   # online-offline-online. This could be accidental, or the user 
   # seeing if we can handle some extended test scenarios.

   # Dummy test data.
   # $script:batt_array = "1 online 100", "2 offline 100", "3 offline 92", "4 offline 90", "5 online 95",
   #   "6 offline 94", "7 offline 93", "8 offline 92"
   # $script:batt_array = "1 offline 90", "2 online 91"
   # $script:batt_array = "1 online 90", "2 offline 90.0001", "193 offline 87.0005"
   # $script:batt_array = "1 online 90", "2 offline 90.0", "193 offline 91"


   # Initialization for parsing data
   $script:batt_est_time_min = 0
   $array_cnt=$script:batt_array.count
   # "estimate_battery_life array_cnt=$array_cnt"
   $interval_cnt = 0
   $interval_start_life = 0
   $interval_start_sec = 0
   $interval_finish_life = 0
   $interval_finish_sec = 0
   $start_batt_life = -1
   $total_discharge_sec = 0
   $weighted_numerator = 0

   # Parse the collected data
   for ($i = 0; $i -lt $array_cnt; $i++) {

      # Get next sample and split out parameters
      $temp1 = $script:batt_array[$i]
      $temp2 = $temp1.split(" ")
      $b_sec = $temp2[0]
      $b_state = $temp2[1]
      $b_life = $temp2[2]
      # log_debug "estimate_battery_life i=$i temp1=$temp1"
      log_info "estimate_battery_life i=$i b_sec=$b_sec b_state=$b_state b_life=$b_life%"

      # Save initial battery life.
      if ($start_batt_life -eq -1) {
         $start_batt_life = $b_life
      }

      # Ignore initial online data.
      if ($b_state -match "online" -and $interval_start_sec -eq 0) {
         # log_debug "estimate_battery_life ignoring initial online data i=$i b_sec=$b_sec b_state=$b_state b_life=$b_life%"
         continue
      }

      # Look for start of a discharge iterval.
      if ($b_state -match "offline" -and $interval_start_sec -eq 0) {
         $interval_start_life = $b_life
         $interval_start_sec = $b_sec
         $interval_cnt++
         log_debug "estimate_battery_life starting interval i=$i interval_start_sec=$interval_start_sec interval_start_life=$interval_start_life%"
         continue
      }

      # Collect most recent intermediate sample. That way we have it stored
      # when we hit the end of the data or we find a sample where we go online.
      # This is NOT the start discharge interval sample!
      if ($b_state -match "offline" -and $interval_start_sec -ne 0) {
         $interval_finish_life = $b_life
         $interval_finish_sec = $b_sec
         log_debug "estimate_battery_life continuing interval i=$i interval_finish_sec=$interval_finish_sec interval_finish_life=$interval_finish_life%"
         continue
      }

      # When we find an online sample, this marks the end of the current discharge interval.
      if ($b_state -match "online" -and $interval_start_sec -ne 0) {
         # Do we have both start & finish data for the current discharge cycle?
         if ($interval_start_sec -ne 0 -and $interval_finish_sec -ne 0) {
            # Add the current interval discharge data to the running weighted totals.
            $delta_life = $interval_finish_life - $interval_start_life # gives negative number
            $delta_sec = $interval_finish_sec - $interval_start_sec
            log_info "estimate_battery_life end of interval i=$i b_state=$b_state delta_life=$delta_life% delta_sec=$delta_sec"
            $weighted_numerator = $weighted_numerator - ($delta_life * $delta_sec) # want a positive number
            $total_discharge_sec = $total_discharge_sec + $delta_sec
            log_debug "estimate_battery_life end interval i=$i weighted_numerator=$weighted_numerator total_discharge_sec=$total_discharge_sec"
         }

         # Reset parser state info.
         $interval_start_life = 0
         $interval_start_sec = 0
         $interval_finish_life = 0
         $interval_finish_sec = 0

         # The rest of the online sample data is of no interest.
         continue
      }

      # Anything else is an error.
      log_error "estimate_battery_life i=$i should NOT go here: $b_sec $b_state $b_life% interval_cnt=$interval_cnt interval_start_life=$interval_start_life% interval_start_sec=$interval_start_sec interval_finish_life=$interval_finish_life% interval_finish_sec=$interval_finish_sec"
   }

   # We have reached the end of the aray data. Do we have an interval 
   # stored up? If so, the end of data implies the end of the sample,
   # even if we are still offline.
   if ($interval_start_sec -ne 0 -and $interval_finish_sec -ne 0) {
      $delta_life = $interval_finish_life - $interval_start_life # gives negative number
      $delta_sec = $interval_finish_sec - $interval_start_sec
      log_info "estimate_battery_life end of data delta_life=$delta_life% delta_sec=$delta_sec"
      $weighted_numerator = $weighted_numerator - ($delta_life * $delta_sec) # want a positive number
      $total_discharge_sec = $total_discharge_sec + $delta_sec
      log_debug "estimate_battery_life end of data weighted_numerator=$weighted_numerator total_discharge_sec=$total_discharge_sec"
   }

   # Estimated battery consumption rate/min
   $min_test_sec = $script:battery_test_discharge_min * 60
   $max_life_min = 240 # Typical battery upper limit, in minutes
   log_info "estimate_battery_life weighted_numerator=$weighted_numerator total_discharge_sec=$total_discharge_sec"
   if ($total_discharge_sec -ge $min_test_sec -and $total_discharge_sec -gt 0) {
      $weighted_discharge = $weighted_numerator / $total_discharge_sec # Covers one or more discharge intervals
      $rate_sec = $weighted_discharge / $total_discharge_sec # battery discharge rate per second
      if ($rate_sec -lt 0) {
         log_error "estimate_battery_life invalid rate_sec=$rate_sec, set to 0"
         $rate_sec = 0
      }
      $rate_min = $rate_sec * 60 # battery discharge rate per minute
      log_info "estimate_battery_life weighted_discharge=$weighted_discharge rate_sec=$rate_sec rate_min=$rate_min start_batt_life=$start_batt_life%"
      if ($rate_min -ne 0) {
         $script:batt_est_time_min = $start_batt_life / $rate_min
         if ($script:batt_est_time_min -gt $max_life_min) {
            $script:batt_est_time_min = $max_life_min
         }

      } else {
         # Some batteries may not show any appreciable discharge in a short time interval,
         # so show the typical maximum battery life.
         $script:batt_est_time_min = $max_life_min
      }
      $temp = "{0:0}" -f $script:batt_est_time_min
      log_bold "estimate_battery_life batt_est_time_min=$temp minutes"

   } else {
      log_error "estimate_battery_life total battery discharge time was $total_discharge_sec seconds, need minimum $min_test_sec seconds, cant estimate battery life time."
   }
}


#==================== find_desktop ================================
# Searches thru the controls found on the desktop. Appears to
# include all other open windows as well.
#
# Calling parameters: class_patt title_patt
#
# Returns: none
# Sets variables: $script:hnd_array
#==================================================================
function find_desktop ($class_patt="", $title_patt="") {

   # Initialization
   $script:hnd_array = @()
   if ($class_patt -eq "") {
      $class_patt = ".*"
   }
   if ($title_patt -eq "") {
      $title_patt = ".*"
   }
   # log_debug "find_desktop class_patt=$class_patt title_patt=$title_patt"

   # Get current list of desktop controls.
   $ctl_list = select-control -window $script:desk_hnd -recurse
   $found = 0
   $result = ""
   $total = 0

   # Filter out controls by title or class
   foreach ($ctl in $ctl_list) {
      # get-variable ctl
      $total++
      $c=$ctl.Class
      $h=$ctl.Handle
      $t=$ctl.Title
      $l=$t.length
      if ($l -gt 20) {
         $l = 20
      }
      $t = $t.Substring(0,$l) # get errors if you ask for charactars after end of string!
      # "c=$c h=$h t=$t"

      if ($c -match $class_patt) {
         $class_ok = $true
      } else {
         $class_ok = $false
      }

      if ($t -match $title_patt) {
         $title_ok = $true
      } else {
         $title_ok = $false
      }

      # "c=$c h=$h t=$t class_ok=$class_ok title_ok=$title_ok"
      if ($class_ok -and $title_ok) {
         # "FOUND: c=$c h=$h t=$t"
         $found++
         $result = "$result c=$c h=$h t=$t `n"
         $script:hnd_array += $h # add to end of array
         continue
      }
   }
   log_info "find_desktop class_patt=$class_patt title_patt=$title_patt result: `n$result `ntotal=$total found=$found hnd_array=$script:hnd_array"
}


#==================== get_age_timestamp ===========================
# If a battery is present in the PC, prompts the user to unplug 
# the AC power so the battery test can run.
#
# Calling parameters: timestamp
# Returns: null
# Sets variables: $script:curr_age
#==================================================================
function get_age_timestamp ($timestamp="") {

   # Initialization
   $script:curr_age = 1000000000 # default value should trigger errors

   # Clean up calling parameter
   # "timestamp=$timestamp"
   $timestamp = $timestamp -replace "\(.*\)"
   $timestamp = $timestamp -replace "at\s*"
   $timestamp = $timestamp -replace "Today\s*"
   $timestamp = $timestamp.trim()

   # Convert timestamp to seconds.
   try {
      $EpochDiff = New-TimeSpan "01 January 1970 00:00:00" $timestamp
      $ts_sec = [INT] $EpochDiff.TotalSeconds
      remove-variable EpochDiff  # make sure no old data is leftover
   } catch {
      $ts_sec = 0 
      $msg = $error | select-object -first 1
      log_error "get_age_timestamp timestamp=$timestamp got: $msg"
   }

   # Get current date/time in seconds.
   $EpochDiff = New-TimeSpan "01 January 1970 00:00:00" $(Get-Date)
   $curr_sec = [INT] $EpochDiff.TotalSeconds
   remove-variable EpochDiff  # make sure no old data is leftover

   # Get age diffrence, in hours.
   $script:curr_age = $curr_sec - $ts_sec
   $script:curr_age = $script:curr_age / 3600 # convert to hours
   log_debug "get_age_timestamp timestamp=$timestamp ts_sec=$ts_sec curr_sec=$curr_sec curr_age=$script:curr_age hrs" 
}


#==================== get_battery_status ==========================
# If a battery is present in the PC, prompts the user to unplug 
# the AC power so the battery test can run.
#
# Calling parameters: <-log>
# -log option will log the current battery data sample
# Returns: null
# Sets variables: $script:batt_array, $script:batt_life,
#                 $script:batt_state
#==================================================================
function get_battery_status {

   # Initialization
   $script:batt_life = ""
   $script:batt_state = ""
   $EpochDiff = New-TimeSpan "01 January 1970 00:00:00" $(Get-Date)
   $curr_sec = [INT] $EpochDiff.TotalSeconds
   remove-variable EpochDiff  # make sure no old data is leftover

   # Get current battery info
   $ps = [Windows.Forms.SystemInformation]::PowerStatus
   $status = $ps.BatteryChargeStatus
   $script:batt_state = $ps.PowerLineStatus
   $script:batt_life = $ps.BatteryLifePercent
   $script:batt_life = $script:batt_life * 100
   remove-variable ps # make sure no old data is leftover

   # Check if we actually have a battery.
   if ($status -match "no.*sys.*batt") {
      # No battery found. This also covers a laptop with the battery removed.
      $script:batt_life = -1
      $script:batt_state = "NoBattery"
   }

   # Always add the current sample to batt_array.
   $script:batt_array += "$curr_sec $script:batt_state $script:batt_life"

   # Optionally log the current sample.
   if ($args -match "-log") {
      $msg = "get_battery_status curr_sec=$curr_sec status=$status batt_state=$script:batt_state batt_life={0:0.00}%" -f $script:batt_life
      log_info $msg
   }
}


#==================== get_clipboard ===============================
# Gets the current content of the windows clipboard.
#
# Calling parameters: none
# Returns: null
# Sets variables: $script:clipboard
#==================================================================
# from: http://stackoverflow.com/questions/1567112/convert-keith-hills-powershell-get-clipboard-and-set-clipboard-to-a-psm1-script
# NB: PSCX module has clipboard routine that can also copy graphics

function get_clipboard {

   $tb = New-Object System.Windows.Forms.TextBox
   $tb.Multiline = $true
   $tb.Paste()
   $script:clipboard = $tb.Text
   log_info "get_clipboard script:clipboard=$script:clipboard"
}


#==================== get_controls ================================
# Gets all the controls for the specified window object by default.
# There are options to allow the choice of main window controls
# only or the choice of child window controls only.
#
# NB: Only the first level children windows are searched. This
# routine is NOT fully recursive. If you want second or third
# level children information, you need to call this routine
# with the window object of a lower level child in order to 
# get the information of the next lower level child.
#
# Calling parameters: obj <-mainonly> <-childonly>
#
# -mainonly  option shows controls for main window only, ignores
#            child windows, if any.
# -childonly option shows controls for child windows, if any and
#            ignores the main window controls.
#
# Returns: null
# Sets variables: $script:controls
#==================================================================
function get_controls ($obj="") {

   # Initialization. @() wipes out any existing data. 
   # NB: We put a sanity check here just to be sure.
   $script:controls = @() 
   foreach ($ctl in $script:controls) {
      log_error "get_controls: obj=$obj args=$args found leftover data: $script:controls"
      return
   }

   # Sanity check.
   if (!$obj) {
      log_error "get_controls invalid obj=$obj args=$args"
      return
   }

   # Parse optional args
   $child_only = $false
   $main_only = $false
   foreach ($opt in $args) {

      # Ignore null args
      $opt = $opt.trim()
      # "opt=$opt"
      if ($opt -eq "") {
         continue
      }

      # Look for -childonly option
      if ($opt -eq "-childonly") {
         $child_only = $true
         continue
      }

      # Look for -mainonly option
      if ($opt -eq "-mainonly") {
         $main_only = $true
         continue
      }

      # Invalid option ==> error
      log_error "get_controls obj=$obj args=$args invalid option: $opt"
      return
   }
   # log_info "get_controls obj=$obj child_only=$child_only main_only=$main_only"

   # Decode the window object.
   # $obj = "" # test code
   $handle = $obj.Handle
   $name = $obj.ProcessName
   $title = $obj.Title
   # log_info "get_controls handle=$handle name=$name title=$title"

   # Sanity check.
   if (!$handle -or $handle -eq "" -or $handle -eq 0) {
      log_error "get_controls obj=$obj args=$args name=$name title=$title, invalid handle=$handle"
      return
   }

   # Look for main window controls.
   if (!$child_only) {
      $x = select-control -window $obj -recurse
      # log_info "get_controls args=$args handle=$handle name=$name title=$title main window controls: $x`n`n"
      $script:controls += $x # adds to end of existing array
   }

   # Look for the first level children windows and related controls.
   # If you want to see the information for the second or lower level
   # children, you need to call this routine with the appropriately
   # lower level window object.
   if (!$main_only) {
      $ch_w = select-childwindow -window $obj
      foreach ($ch in $ch_w) {
         # Skip null entries
         if (!$ch) {
            continue
         }

         # Decode the child window object
         # "child=$ch"
         # get-variable ch
         $h = $ch.Handle
         $n = $ch.ProcessName
         $t = $ch.Title
      
         # Look for child window controls.
         $y = select-control -window $ch -recurse
         $script:controls += $y # adds to end of existing array
         # log_info "get_controls args=$args h=$h n=$n t=$t child window controls: $y`n`n"
         # foreach ($c in $y) {
         #    if ($c) {
         #       "c=$c"
         #       get-variable c
         #    }
         # }
      }
   }

   # Logging of the controls is now done by calling routines, typically only
   # if the desired control is not found.
   # log_info "get_controls args=$args handle=$handle name=$name title=$title controls=$script:controls`n`n`n"

   # Debug code. Do we have one contiguous array of controls?
   # Really dont want an array where each element is itself an array!
   # $cnt = $script:controls.count
   # "`n`nget_controls cnt=$cnt"
   # foreach ($ctl in $script:controls) {
   #    "get_controls ctl=$ctl"
   # }
}


#==================== get_discharge_sec ===========================
# Gets total battery discharge time to date from the data in
# $script:batt_array.
#
# Calling parameters: null
# Returns: null
# Sets variables: $script:discharge_sec
#==================================================================
function get_discharge_sec {

   # NB: The battery discharge data may have more than one cycle of
   # online-offline-online. This could be accidental, or the user 
   # seeing if we can handle some extended test scenarios.

   # Dummy test data.
   # $script:batt_array = "1 online 100", "2 offline 100", "3 offline 92", "4 offline 90", "5 online 95",
   #  "6 offline 94", "7 offline 93", "8 offline 92"
   # $script:batt_array = "1 offline 90", "2 online 91"
   # $script:batt_array = "1 online 90", "2 offline 90.0001", "193 offline 87.0005"
   # $script:batt_array = "1 online 90", "2 offline 90.0", "193 offline 91"

   # Initialization for parsing data
   $script:discharge_sec = 0
   $array_cnt=$script:batt_array.count
   # "get_discharge_sec array_cnt=$array_cnt"
   $interval_cnt = 0
   $interval_start_sec = 0
   $interval_finish_sec = 0
   $total_discharge_sec = 0

   # Parse the collected data
   for ($i = 0; $i -lt $array_cnt; $i++) {

      # Get next sample and split out parameters
      $temp1 = $script:batt_array[$i]
      $temp2 = $temp1.split(" ")
      $b_sec = $temp2[0]
      $b_state = $temp2[1]
      $b_life = $temp2[2]
      # log_debug "get_discharge_sec i=$i temp1=$temp1"
      log_debug "get_discharge_sec i=$i b_sec=$b_sec b_state=$b_state b_life=$b_life%"

      # Ignore initial online data.
      if ($b_state -match "online" -and $interval_start_sec -eq 0) {
         # log_debug "get_discharge_sec ignoring initial online data i=$i b_sec=$b_sec b_state=$b_state b_life=$b_life%"
         continue
      }

      # Look for start of a discharge iterval.
      if ($b_state -match "offline" -and $interval_start_sec -eq 0) {
         $interval_start_sec = $b_sec
         $interval_cnt++
         # log_debug "get_discharge_sec starting interval i=$i interval_start_sec=$interval_start_sec"
         continue
      }

      # Collect most recent intermediate sample. That way we have it stored
      # when we hit the end of the data or we find a sample where we go online.
      if ($b_state -match "offline" -and $interval_start_sec -ne 0) {
         $interval_finish_sec = $b_sec
         # log_debug "get_discharge_sec continuing interval i=$i interval_finish_sec=$interval_finish_sec"
         continue
      }

      # When we find an online sample, this marks the end of the current discharge interval.
      if ($b_state -match "online" -and $interval_start_sec -ne 0) {
         # Do we have both start & finish data for the current discharge cycle?
         if ($interval_start_sec -ne 0 -and $interval_finish_sec -ne 0) {
            # Add the current interval discharge time to the running total.
            $delta_sec = $interval_finish_sec - $interval_start_sec
            log_info "get_discharge_sec end of interval i=$i b_state=$b_state delta_sec=$delta_sec"
            $total_discharge_sec = $total_discharge_sec + $delta_sec
            # log_debug "get_discharge_sec end interval i=$i total_discharge_sec=$total_discharge_sec"
         }

         # Reset parser state info.
         $interval_start_sec = 0
         $interval_finish_sec = 0

         # The rest of the online sample data is of no interest.
         continue
      }

      # Anything else is an error.
      log_error "get_discharge_sec i=$i should NOT go here: $b_sec $b_state $b_life% interval_cnt=$interval_cnt interval_start_sec=$interval_start_sec interval_finish_sec=$interval_finish_sec"
   }

   # We have reached the end of the aray data. Do we have an interval 
   # stored up? If so, the end of data implies the end of the sample,
   # even if we are still offline.
   if ($interval_start_sec -ne 0 -and $interval_finish_sec -ne 0) {
      $delta_sec = $interval_finish_sec - $interval_start_sec
      log_info "get_discharge_sec end of data delta_sec=$delta_sec"
      $total_discharge_sec = $total_discharge_sec + $delta_sec
      # log_debug "get_discharge_sec end of data total_discharge_sec=$total_discharge_sec"
   }

   # Log the result
   $script:discharge_sec = $total_discharge_sec
   log_info "get_discharge_sec discharge_sec=$script:discharge_sec"
}


#==================== get_explorer_disk_properties ================
# Use Windows explorer, right click on C: and choose Properties 
# to bring up the pie chart of disk
