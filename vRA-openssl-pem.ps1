#Assumptions
#1 - A working internal certificate authority is setup
#2 - A template in your CA setup provides Client and Server authentication
#3 - OpenSSL has been downloaded and placed in C:\OpenSSL
#4 - Account running commands in script has appropriate rights on template in CA
#5 - Each OpenSSL configuration has been configured with appropriate DNS names (script creates this dynamically with input from XML files)

param
(
	[String] $ConfigurationFile = $(throw "Please specify the configuration file for the Content move.`r`nExample:`r`n`tGet-MachineLookup.ps1 -ConfigurationFile `"E:\Directory\ChangeThisPath.xml`"")
)

switch (Test-Path $ConfigurationFile)
	{
	True {Write-Host "Using $ConfigurationFile For Script Variables"
		$P = [xml](Get-Content $ConfigurationFile)
	}
	False {Write-Host "$ConfigurationFile Not Found For Script Variables - Quitting"
		Exit
		}
	}


#Get Properties and assign to local variables from XML file
[string]$certPath = $P.Configuration.Properties.certPath
[string]$subjAltName = $P.Configuration.Properties.subjAltName
[string]$commonName = $P.Configuration.Properties.commonName

[string]#OpenSSL config settings
[string]$openSSLCFGfileName = $P.Configuration.Properties.openSSLCFGfileName
[string]$countryName = $P.Configuration.Properties.countryName
[string]$stateOrProvinceName = $P.Configuration.Properties.stateOrProvinceName
[string]$localityName = $P.Configuration.Properties.localityName
[string]$organizationName = $P.Configuration.Properties.organizationName
[string]$organizationalUnitName = $P.Configuration.Properties.organizationalUnitName

[string]#General variables
[string]$CertificateTemplateName = $P.Configuration.Properties.CertificateTemplateName
[string]$CertificateKeyLength = $P.Configuration.Properties.CertificateKeyLength
[string]$RootCA = $P.Configuration.Properties.RootCA
[string]$OpenSSLPath = $P.Configuration.Properties.OpenSSLPath
[string]$OpenSSLRootDir = $P.Configuration.Properties.OpenSSLRootDir
[string]$CertPassword = $P.Configuration.Properties.CertPassword

function CreateOpenSSLConfig([string]$Path, [string]$subjAltName, [string]$commonName)
{
	Add-Content -path $Path\$openSSLCFGfileName  -value "[ req ]"
	Add-Content -path $Path\$openSSLCFGfileName  -value "default_bits = 2048"
	Add-Content -path $Path\$openSSLCFGfileName  -value "default_keyfile = rui.key"
	Add-Content -path $Path\$openSSLCFGfileName  -value "distinguished_name = req_distinguished_name"
	Add-Content -path $Path\$openSSLCFGfileName  -value "encrypt_key = no"
	Add-Content -path $Path\$openSSLCFGfileName  -value "prompt = no"
	Add-Content -path $Path\$openSSLCFGfileName  -value "string_mask = nombstr"
	Add-Content -path $Path\$openSSLCFGfileName  -value "req_extensions = v3_req"
	Add-Content -path $Path\$openSSLCFGfileName  -value ""
	Add-Content -path $Path\$openSSLCFGfileName  -value "[ v3_req ]"
	Add-Content -path $Path\$openSSLCFGfileName  -value "basicConstraints = CA:FALSE"
	Add-Content -path $Path\$openSSLCFGfileName  -value "keyUsage = digitalSignature,  keyEncipherment,  dataEncipherment, nonRepudiation"
	Add-Content -path $Path\$openSSLCFGfileName  -value "extendedKeyUsage = serverAuth,  clientAuth"
	Add-Content -path $Path\$openSSLCFGfileName  -value "subjectAltName = $($subjAltName)"
	Add-Content -path $Path\$openSSLCFGfileName  -value ""						  
	Add-Content -path $Path\$openSSLCFGfileName  -value "[ req_distinguished_name ]"
	Add-Content -path $Path\$openSSLCFGfileName  -value "countryName = $($countryName)"
	Add-Content -path $Path\$openSSLCFGfileName  -value "stateOrProvinceName = $($stateOrProvinceName)"
	Add-Content -path $Path\$openSSLCFGfileName  -value "localityName = $($localityName)"
	Add-Content -path $Path\$openSSLCFGfileName  -value "0.organizationName = $($organizationName)"
	Add-Content -path $Path\$openSSLCFGfileName  -value "organizationalUnitName = $($organizationalUnitName)"
	Add-Content -path $Path\$openSSLCFGfileName  -value "commonName = $($commonName)"
}

function CreateCertificate([string]$Path)
{
	[string]$certPathCMD = "$($OpenSSLPath) req -new -nodes -out $($Path)\vra-cert.csr -keyout $($Path)\vra-cert.key -config $($Path)\openssl.cfg"
	Add-Content -path "$($Path)\cmds.txt" -value $certPathCMD
	Invoke-Expression -Command $certPathCMD

	#Write RSA key
	[string]$certRSACMD = "$($OpenSSLPath) rsa -in  $($Path)\vra-cert.key -out  $($Path)\vra-cert.key"
	Add-Content -path "$($Path)\cmds.txt" -value $certRSACMD
	Invoke-Expression -Command $certRSACMD

	#Variables for CSR, Certificate and P7B
	$CSRPath = "$($Path)\vra-Cert.csr"
	$CertificatePath = "$($Path)\vra-Cert.cer"
	$p7bPath = "$($Path)\vra-Cert.p7b"

	#Call CA authority and retrieve certificates, p7bfile
	$certCMD = "$Env:SystemRoot\System32\certreq -attrib `"CertificateTemplate:$($CertificateTemplateName)`" -submit -config $RootCA $CSRPath $CertificatePath $p7bPath"
	Add-Content -path "$($Path)\cmds.txt" -value $certCMD
	Invoke-Expression -Command $certCMD 

	#This adds root CA and certificate to PEM files
	$ChainPEMFile = "$($OpenSSLPath) pkcs7 -in $($p7bPath) -print_certs -out $($Path)\chain.pem"
	Add-Content -path "$($Path)\cmds.txt" -value $ChainPEMFile
	Invoke-Expression -Command $ChainPEMFile
}

if(Test-Path -path $OpenSSLRootDir)
{
	#Create Path for config, files 
	New-Item -ItemType Directory -path $certPath -force

	#Create OpenSSL.cfg
	CreateOpenSSLConfig -Path $certPath -subjAltName $subjAltName -commonName $commonName 

	#Create CSR, Request Cert and create PEM file
	CreateCertificate -Path $certPath
}
else
{
	Exit
}