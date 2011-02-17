 o       o     o    o   o             o          
 |       |     |    |\ /|          o  |          
 o   o   o o-o O-o  | O | o-o o-o    -o- o-o o-o 
  \ / \ /  |-' |  | |   | | | |  | |  |  | | |   
   o   o   o-o o-o  o   o o-o o  o |  o  o-o o  

About
============================
WebMonitor is a project comprising multiple sub-projects for the metering of
internet traffic.

Currently these sub-projects are WebMonitorDaemon, WebMonitorMaster and
WebMonitorWatcher.

The WebMonitorDaemon sub-project is designed to run in the background of a
computer where the internet traffic is to be metered, it records the traffic and
reports back to WebMonitorMaster.

The WebMonitorMaster sub-project is comprised of two parts, the frontend and
the backend. The frontend is a web-based human interface for the backend. The
backend is where all of the work is done, it accepts metering information,
stores it and makes it avaliable to either the frontend or the
WebMonitorWatcher. This sub-project also handles all of the users, their
priveledges and thier settings, all other sub-projects defer to this project for
their login systems.

The WebMonitorWatcher sub-project is a desktop based and much simplified
interface for viewing the data, either the realtime data directly from the
WebMonitorDaemon or from the WebMonitorMaster backend.
	
Copyright
============================
See COPY.txt for more info.