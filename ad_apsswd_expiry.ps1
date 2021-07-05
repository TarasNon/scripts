$ver = "0.4"
$dt=Get-Date -Format "dd-MM-yyyy"
New-Item -ItemType directory log -Force | out-null #Создаю директорию для логов

$global:logfilename="log\"+$dt+"_LOG.log"
[int]$global:errorcount=0 #Ведем подсчет ошибок
[int]$global:warningcount=0 #Ведем подсчет предупреждений

function global:Write-log	# Функция пишет сообщения в лог-файл и выводит на экран.
{param($message,[string]$type="info",[string]$logfile=$global:logfilename,[switch]$silent)	
	$dt=Get-Date -Format "dd.MM.yyyy HH:mm:ss"	
	$msg=$dt + "`t" + $type + "`t" + $message #формат: 01.01.2001 01:01:01 [tab] error [tab] Сообщение
	Out-File -FilePath $logfile -InputObject $msg -Append -encoding unicode
	if (-not $silent.IsPresent) 
	{
		switch ( $type.toLower() )
		{
			"error"
			{			
				$global:errorcount++
				write-host $msg -ForegroundColor red			
			}
			"warning"
			{			
				$global:warningcount++
				write-host $msg -ForegroundColor yellow
			}
			"completed"
			{			
				write-host $msg -ForegroundColor green
			}
			"info"
			{			
				write-host $msg
			}			
			default 
			{ 
				write-host $msg
			}
		}
	}
}


$ProgrammName="AD passwd expiration view"

try
{
	# Функция вывода информации на экран и записи в лог
	$global:logfilename = "log`\"+ $ProgrammName +".log"
	write-log "$ProgrammName (ver $ver) started."    
write-log "--------------------------------------------------------------------------------------"

}
catch 
{		
	return "Error loading functions!!!"
}

Import-Module activedirectory
# получаем список всех активированных российских пользователей, у которых установлен срок действия пароля
$NotificationCounter = 0
$OU = "OU=Users,OU=Odincovo,OU=Offices,OU=ROOT,DC=ecco,DC=ru"
$ADAccounts = Get-ADUser -LDAPFilter "(objectClass=user)" -searchbase $OU -properties PasswordExpired, employeeNumber, PasswordNeverExpires, PasswordLastSet, Mail, mobile, Enabled | Where-object {$_.Enabled -eq $true -and $_.PasswordNeverExpires -eq $false}

# для каждого пользователя
foreach ($ADAccount in $ADAccounts) 
#проверяем политику сложности пароля
{
 $accountFGPP = Get-ADUserResultantPasswordPolicy $ADAccount
                if ($accountFGPP -ne $null)
		  {
                 $maxPasswordAgeTimeSpan = $accountFGPP.MaxPasswordAge
		  }
		else
		  {
                 $maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
           }
#Заполняем переменные пользовательскими данными
	$samAccountName = $ADAccount.samAccountName
	$userEmailAddress = $ADAccount.mail
	$userPrincipalName = $ADAccount.UserPrincipalName
   	$userStorePassword = $ADAccount.employeeNumber
	$usermobile = $ADAccount.mobile
	# Для каждого из пользователей, не успевшего сменить пароль
	if ($ADAccount.PasswordExpired)
	   {
                # Считываем пароль из атрибутного поля AD
	# Если нет ранее сохранённого пароля, устанавливаем пароль по умолчанию - Pa$$w0rd
	if ($userStorePassword -eq $NULL -or $useStorePassword -eq " ")
		{
			$userStorePassword = "Pa$$w0rd"		}
        # Заменяем пароль на новый
        #$newpwd = ConvertTo-SecureString -String $userStorePassword -AsPlainText –Force
        #Set-ADAccountPassword -Identity $samAccountName -NewPassword $newpwd –Reset
	# Сохраняем новый пароль и номер мобильного телефона в TXT файл
    
	
       # Делаем запись в журнале
        write-log "Пароль УЗ  $samAccountName ПРОСРОЧЕН"
       # write-log "--------------------------------------------------------------------------------------"
	      
        # Очищаем атрибутное поле AD
        #Set-ADUser $samAccountName -employeeNumber $null
	   }
	else
        # Для всех тех, у кого пароль истекает завтра, то есть $DaysToExpireDD меньше 3
	   {
	   $ExpiryDate = $ADAccount.PasswordLastSet + $maxPasswordAgeTimeSpan
	   $TodaysDate = Get-Date
	   $DaysToExpire = $ExpiryDate - $TodaysDate
       #Вычисляем дней до просрочки в DaysToExpireDD в формате дней
	   $DaysToExpireDD = $DaysToExpire.ToString() -Split ("\S{17}$")
		$FExpiryDate = get-date -date $ExpiryDate -Format "dd.MM.yyyy HH:mm:ss"	
            if (($DaysToExpire.Days -le 3))
            		{
                    Write-log "Пароль УЗ $samAccountName истекает: $FExpiryDate. Осталось дн.: $DaysToExpireDD"
# Генерируем новый пароль в переменную $generated_password
                    #$generated_password = Get-RandomPassword 10
                   #write-log "Generated password: $samAccountName - $generated_password"
		   

                    # Записываем новый пароль в атрибутное полe AD. Будем пользоваться атрибутом employeeNumber
                    #Set-ADUser $samAccountName -employeeNumber $generated_password
}
}
}
 $FTodaysDate = get-date -date $TodaysDate -Format "dd.MM.yyyy HH:mm:ss"	
Write-log "Выполнение скрипта завершено  $FTodaysDate"
Write-log "======================================================================================"    
write-log "--------------------------------------------------------------------------------------"                 
Write-Host "Press any key to continue ... or Ctrl+C to abort"

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# SIG # Begin signature block
# MIIKagYJKoZIhvcNAQcCoIIKWzCCClcCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSlNkkHcyz3yXIcCRARxOgfVj
# VoegggbXMIIG0zCCBbugAwIBAgITHwAAABFJfn+v84xC3QAAAAAAETANBgkqhkiG
# 9w0BAQUFADBFMRIwEAYKCZImiZPyLGQBGRYCcnUxFDASBgoJkiaJk/IsZAEZFgRh
# cHNrMRkwFwYDVQQDExBTUlYtQVBTSy0wMDAxLUNBMB4XDTE2MTEwNjEwNDI0MVoX
# DTE3MTEwNjEwNDI0MVowdzESMBAGCgmSJomT8ixkARkWAnJ1MRQwEgYKCZImiZPy
# LGQBGRYEYXBzazENMAsGA1UECxMEUk9PVDEOMAwGA1UECxMFVXNlcnMxLDAqBgNV
# BAMMI9CU0LzQuNGC0YDQuNC5INCk0LXQtNC+0YDQtdC90LrQvtCyMIICIjANBgkq
# hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv3MpSrZOr77SBBtQLUg06Z//AZfB4DTd
# L5+r/jz+oUUL5JmvGtqhTZlk+JGNcR09EcEgdhR5Yrr5A12v9v/RhYTXl6Js5PAu
# LEJmCabCd4V32UEzvVERjz5PQjOKtGvNofT853gGzagoI4sTgvp/YOJ8fcofk7wi
# myCFZ4rZ7EJODoECTey+sU1AY1bKa6pWWd+QKKCIIGp6q1URcesBLJp96JDow4Gk
# 47mezJgiNTnd4C0Muf9HJ02nN+A/v9GA8Vdor+H9NPc8RVtgf3dRoZ4BXBUzoHP+
# Tx/HbFV/ATFT9do/zsqDIPYCvj1+sjsE5q3OYF/EnNOXvaKXDtuPLzrf0+OLuSOO
# HKgRxsyfuv8iGmsoamV5F3cqkBsgohqnRdWFKCKhzEa2QdObear3ngbnfL4vK/UY
# Bp29RRHJJ+D2+sdAWRhXAkDfT2vVAUTipIxyoCe2wuTdtPk0mxmGUTjY30oJeWGO
# 87CXrHEcPVwmYhCi0472E9efTQwBRO68paJ78x+uyNepDRZHDA4H5+dvagSpKfSK
# OmZkqCv9SLqF2XRb7SBxkO46q0iGL8VH+fUVtizGmHsGhDsWsD17ELBf8XrFHNy/
# HU0X9ugkGGuEtMxErTbBGgUGnoBB1kfJTbsx79AkktWXuYG7K2HSzh+W0XPMtLs/
# eL6VRSrd1acCAwEAAaOCAogwggKEMD0GCSsGAQQBgjcVBwQwMC4GJisGAQQBgjcV
# CIOVmEWFt+50hPmZGIPenQCH5d8LRIS7lRSDwpM2AgFkAgEFMBMGA1UdJQQMMAoG
# CCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIHgDAbBgkrBgEEAYI3FQoEDjAMMAoGCCsG
# AQUFBwMDMB0GA1UdDgQWBBRXlQ/x6CkQrpM0Me7lJtc5DA+U5TAfBgNVHSMEGDAW
# gBS1SgUaBrm0ag7XJjHmxbSbDDww9TCB0AYDVR0fBIHIMIHFMIHCoIG/oIG8hoG5
# bGRhcDovLy9DTj1TUlYtQVBTSy0wMDAxLUNBLENOPVNSVi1BUFNLLTAwMDEsQ049
# Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNv
# bmZpZ3VyYXRpb24sREM9YXBzayxEQz1ydT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25M
# aXN0P2Jhc2U/b2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwgb4GCCsG
# AQUFBwEBBIGxMIGuMIGrBggrBgEFBQcwAoaBnmxkYXA6Ly8vQ049U1JWLUFQU0st
# MDAwMS1DQSxDTj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2Vy
# dmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1hcHNrLERDPXJ1P2NBQ2VydGlmaWNh
# dGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MC0GA1Ud
# EQQmMCSgIgYKKwYBBAGCNxQCA6AUDBJmZWRvcmVua292QGFwc2sucnUwDQYJKoZI
# hvcNAQEFBQADggEBACNIoEHzw+cQmCUA/5cl48I2+/qXG37ZPqF7rLTx4r81gonB
# hzir2/Ad1VIZGOL9xqnZ/M2n3sDGgRsgquQVL08dIwYYMl7uoyLcBXuZY+ILJDw0
# yJwmLL0P8MqiA3nQnBQKVWeoTiu1sscMUyt1K1MZXdd5iO2SfUg5eALuxA3FfYkY
# AZMp91R6vVTYTrTHe1esI3tJUW3xIBlmeFL2KHrs5/pFBSSNLtrxBc3T8sOgQD3s
# eS3W+cRfFswG80So2P8T/NR0fRUL2E5sDqBm+wb50obND8srzfxXkx6DFLNUQCtF
# R0tZH4s5KrP48ueWXs4PM4H5n/NLtCsYEXbIym0xggL9MIIC+QIBATBcMEUxEjAQ
# BgoJkiaJk/IsZAEZFgJydTEUMBIGCgmSJomT8ixkARkWBGFwc2sxGTAXBgNVBAMT
# EFNSVi1BUFNLLTAwMDEtQ0ECEx8AAAARSX5/r/OMQt0AAAAAABEwCQYFKw4DAhoF
# AKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisG
# AQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcN
# AQkEMRYEFCURs+WbupU+b0VykNlCwb6gxagGMA0GCSqGSIb3DQEBAQUABIICADU0
# wKu9LofXH1Z97RA6qQyw95ostgAtMuGwdUkOW83l/YbunPKKBE4yHpwJyf/40Mid
# Iix6wF2vaN9z0Hm6nY2U7AM9HQTX4iGGINUVdjMCCoPioVJ9FO8PZeb4pB1biYk+
# FcQfeNAIU2W33laNNXxsKpqWXLFg3KpP/E7p0BlZtzpVB5J5AxHQPQaAmOsd72gN
# w7WJrEl2EHvjj1qVxWNmNIOGDf8tZCZT14+K6WPOJyePf0sF747mFYES4lXZcXBp
# B+cDFPUbgJLk07dx08FPEgvQXYgZ3tHyS4DLRGkYiU2N9W+cUc/RMthyh4BNOC+7
# xpAWGfEQgwM7qFrBq20MxKn++J2jn0GQocnAdyStMFssA7VTETvBcWn+vqOVc8HW
# EPlsxkY0Q03atrEfVChjELDnubRmzugIzLiUFiVvWcZMOXxEBuDg+7BHMFkNxpH7
# SN0AX0RD2JkncylZ8oKjRLIM0tBp5Uu3BaqO5ZX1K5tZEDNx2Kuzkgetz6F2jgog
# nLfJmaTipG1ck/2AzYTiX7fXsb6kbk6ApUgi6pN3CdJqFks75FPm0MFSG7DFDo8f
# quJNprjNr761U7A6UeQgQgiFA2b6hU/xxY3bE/DjXYvBInYLhMiQh43lq7o22Ds1
# cIRPbHnUOwe/JGt6Yru1UtbQFjqyeQtyElJzlKbr
# SIG # End signature block
