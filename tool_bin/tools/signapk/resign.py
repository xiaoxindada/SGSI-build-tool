#!/usr/bin/python3
from xml.dom import minidom
import re
import os
import mmap
import subprocess
import fnmatch
import argparse
import fileinput
import codecs
from shutil import rmtree

cwd = os.path.dirname(os.path.realpath(__file__))


def find(pattern, path):
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                return os.path.join(root, name)


parser = argparse.ArgumentParser(
    description="Python Script to resign an Android ROM using custom keys")
parser.add_argument('RomDir', help='ROM Path')
parser.add_argument(
    'SecurityDir', help='Security Dir Path (just like https://android.googlesource.com/platform/build/+/master/target/product/security/)')
parser.add_argument('SignLibrary', help='SignLibs Path')
args = parser.parse_args()
romdir = args.RomDir
securitydir = args.SecurityDir

mac_permissions = find("*mac_permissions*", romdir + "/etc/selinux")

xmldoc = minidom.parse(mac_permissions)
itemlist = xmldoc.getElementsByTagName('signer')
certlen = len(itemlist)

signatures = []
signatures64 = []
seinfos = []
usedseinfos = []

tmpdir = cwd + "/tmp"
signapkjar = cwd + "/signapk.jar"
os_info = os.uname()[0]
signapklibs = args.SignLibrary


def CheckCert(filetoopen, cert):
    f = open(filetoopen)
    s = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
    if s.find(cert) != -1:
        return True
    else:
        return False


def getcert(jar, out):
    check_cert = ['7z', 'l', '-ba', jar, '|', 'rev', '|',
                  'awk \'{print $1}\'', '|' 'grep -q CERT.RSA']
    if subprocess.run(check_cert, stdout=subprocess.PIPE, stderr=subprocess.PIPE).returncode != 0:
        return

    extractjar = "7z e " + jar + " META-INF/CERT.RSA -o" + tmpdir
    x = subprocess.run(
        ['7z', 't', jar], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if x.returncode == 0:
        output = subprocess.check_output(['bash', '-c', extractjar])

    if os.path.exists(tmpdir + "/CERT.RSA"):
        extractcert = "openssl pkcs7 -in " + tmpdir + \
            "/CERT.RSA -print_certs -inform DER -out " + out
        output = subprocess.check_output(['bash', '-c', extractcert])
        os.remove(tmpdir + "/CERT.RSA")


def sign(jar, certtype):
    if not os.path.exists(securitydir + "/" + certtype + ".pk8"):
        print((certtype + ".pk8 not found in security dir"))
        return False

    jartmpdir = tmpdir + "/JARTMP"
    if not os.path.exists(jartmpdir):
        os.makedirs(jartmpdir)

    signjarcmd = "java -XX:+UseCompressedOops -Xms2g -Xmx2g -Djava.library.path=" + signapklibs + " -jar " + signapkjar + " " + securitydir + \
        "/" + certtype + ".x509.pem " + securitydir + "/" + certtype + \
        ".pk8 " + jar + " " + jartmpdir + "/" + os.path.basename(jar)

    movecmd = "mv -f " + jartmpdir + "/" + os.path.basename(jar) + " " + jar
    try:
        output = subprocess.check_output(['bash', '-c', signjarcmd])
        output += subprocess.check_output(['bash', '-c', movecmd])
        print((os.path.basename(jar) + " signed as " + seinfo))
        usedseinfos.append(
            seinfo) if seinfo not in usedseinfos else usedseinfos
    except subprocess.CalledProcessError:
        print(("Signing " + os.path.basename(jar) + " failed"))


index = 0
for s in itemlist:
    signatures.append(s.attributes['signature'].value)
    test64 = codecs.encode(codecs.decode(
        s.attributes['signature'].value, 'hex'), 'base64').decode()
    test64 = test64.replace('\n', '')

    signatures64.append(re.sub("(.{64})", "\\1\n", test64, 0, re.DOTALL))

    seinfos.append(xmldoc.getElementsByTagName('seinfo')
                   [index].attributes['value'].value)
    index += 1

for root, dirs, files in os.walk(romdir):
    for file in files:
        if file.endswith(".apk") or file.endswith(".jar") or file.endswith(".apex") or file.endswith(".capex"):
            jarfile = os.path.join(root, file)

            if not os.path.exists(tmpdir):
                os.makedirs(tmpdir)
            os.chdir(tmpdir)

            out = "foo.cer"
            if os.path.exists(out):
                os.remove(out)

            getcert(jarfile, out)
            if not os.path.exists(out):
                print((file + " : No signature => Skip"))
            else:
                index = 0
                for seinfo in seinfos:
                    if CheckCert(out, signatures64[index].encode()):
                        sign(jarfile, seinfo)
                        break
                    index += 1
                if index == certlen:
                    print((file + " : Unknown => keeping signature"))

index = 0
for s in itemlist:
    oldsignature = s.attributes['signature'].value
    seinfo = xmldoc.getElementsByTagName(
        'seinfo')[index].attributes['value'].value
    index += 1
    if seinfo in usedseinfos:
        pemtoder = "openssl x509 -outform der -in " + \
            securitydir + "/" + seinfo + ".x509.pem"
        output = subprocess.check_output(['bash', '-c', pemtoder])
        newsignature = output.hex()
        for line in fileinput.input(mac_permissions, inplace=True):
            print(line.replace(oldsignature, newsignature), end=' ')

rmtree(tmpdir, True)
