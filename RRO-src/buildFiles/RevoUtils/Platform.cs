﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RevoUtils
{
    public static class Platform
    {
        
        public enum PlatformFlavor { Windows, CentOS, SLES, OpenSUSE, Ubuntu, OSX, UnknownUnix }

        public static System.PlatformID GetPlatform()
        {  
            return Environment.OSVersion.Platform;
        }

        public static PlatformFlavor GetPlatformFlavor()
        {
            System.PlatformID platform = GetPlatform();

            if (platform == PlatformID.Win32NT)
            {
                return PlatformFlavor.Windows;
            }
            else if (platform == PlatformID.Unix)
            {
                if (System.IO.File.Exists("/etc/issue"))
                {
                    string issueText = System.IO.File.ReadAllText("/etc/issue");

                    if (issueText.Contains("CentOS"))
                        return PlatformFlavor.CentOS;
                    else if (issueText.Contains("SLES"))
                        return PlatformFlavor.SLES;
                    else if (issueText.Contains("Ubuntu"))
                        return PlatformFlavor.Ubuntu;
                    else if (issueText.Contains("OpenSUSE"))
                        return PlatformFlavor.OpenSUSE;
                    else
                        return PlatformFlavor.UnknownUnix;
                }
                else
                    return PlatformFlavor.UnknownUnix;
            }
            else if (platform == PlatformID.MacOSX)
            {

            }
            else
            {

            }
            throw new NotImplementedException();
        }
        public static System.Version GetMajorReleaseVersion()
        {
            System.PlatformID platform = GetPlatform();

            if(platform == PlatformID.Win32NT)
            {

            }
            else if(platform == PlatformID.Unix)
            {
                if(System.IO.File.Exists("/etc/issue"))
                {
                    using(var issueFile = System.IO.File.OpenRead("/etc/issue"))
                    {
                        
                    };
                }
            }
            else if (platform == PlatformID.MacOSX)
            {

            }
            else
            {
                
            }
            throw new NotImplementedException();
        }

    }
}
