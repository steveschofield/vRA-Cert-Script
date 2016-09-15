LICENSE - Free to use as you see fit.  BSD was my favorite license and OS back in the day.  I guess it's called Apache BSD.  No strings.. 

To use Scripts, some pre-reqs need to be verified, met

1) Download OpenSSL from repo or download an OpenSSL windows version on the web
	a) Scripts use C:\OpenSSL as default path
	https://github.com/steveschofield/vRA-cert-script
	
2) Update XML files data meet your environment
3) Verify PowerShell execution is at least RemoteSigned on machine running scripts
4) Verify account running scripts has permissions on template defined
5) Verify with your Certificate Administrator Name of the Template used

To use the script

1) Update the XML files with your data
2) Execute powershell script syntax is .\vRA-openssl-pem.ps1 -configurationpath .\vRA-va.xml
3) Look in c:\OpenSSL\Certs\vRAva\ for files. Use PEM file when installing vRA 7

Reference links

https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2090090
http://open902.com/create-a-windows-enterprise-ca-and-issue-certificates-for-vra-and-other-vmware-products-with-examples/
http://cloudadvisors.net/chapter-4-deploying-vrealize-automation/
