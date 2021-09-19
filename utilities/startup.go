package main
import (
	"strings"
	"io/ioutil"
	"os"
	"strconv"
	"os/exec"
	"syscall"
	"regexp"
	"flag"
)
func main() {
	// Read users
	pass_byte, _ := ioutil.ReadFile("/etc/passwd")
	pass_str := string(pass_byte)
	// read config
	user := flag.String("user", "", "current username that should be updated")
	new_user := flag.String("new_user", "", "new username for the update")
	new_uid := flag.String("new_uid", "", "new uid for the update")
	new_gid := flag.String("new_gid", "", "new gid for the update")
	new_home := flag.String("new_home", "", "new home for the update")
	flag.Parse()
	// identify user to update
	record := strings.Split(regexp.MustCompile(*user + "[^\n]+\n").FindString(pass_str),
				":")
	// verify if update necessary
	if len(record) == 7 {
		uid, gid, home := record[2], record[3], record[5]
		if !isFlagPassed("new_user") {
			new_user = user
		}
		if !isFlagPassed("new_uid"){
			new_uid = &uid
		}
		if !isFlagPassed("new_gid") {
			new_gid = &gid
		}
		if !isFlagPassed("new_home") {
			new_home = &home
		}
		uid_int, _ := strconv.Atoi(*new_uid)
		gid_int, _ := strconv.Atoi(*new_gid)
		// Rename home dir
		if home != *new_home {
			cmd0 := exec.Command("mv", home, *new_home)
			cmd0.SysProcAttr = &syscall.SysProcAttr{}
			cmd0.SysProcAttr.Credential = &syscall.Credential{Uid: 0, Gid: 0}
			output0, err0 := cmd0.CombinedOutput()
			if err0 != nil {
				println(err0.Error() + ": " + string(output0))
				return
			}
		}
		// Add symlink if new user
		if user != new_user {
			os.Symlink(*new_home, "/home/" + *new_user)
		}
		// Update user
		new_record := []string{*new_user, "x", *new_uid, *new_gid, record[4],
				       *new_home, record[6]}
		pass_str = strings.Replace(
			pass_str, strings.Join(record, ":"), strings.Join(new_record, ":"), -1)
		pass_file, _ := os.Create("/etc/passwd")
		pass_file.WriteString(pass_str)
		pass_file.Close()
		// Update ownership of certain key directories
		os.Chown(*new_home, uid_int, gid_int)
		os.Chown(*new_home + "/.local", uid_int, gid_int)
		os.Chown(*new_home + "/.local/bin", uid_int, gid_int)
		os.Chown(*new_home + "/.cache", uid_int, gid_int)
		os.Chown(*new_home + "/.cache/pip", uid_int, gid_int)
		os.Chown(*new_home + "/.cache/pip/wheels", uid_int, gid_int)
		os.Chown(*new_home + "/.conda", uid_int, gid_int)
		os.Chown(*new_home + "/.conda/environments.txt", uid_int, gid_int)
		os.Chown(*new_home + "/.condarc", uid_int, gid_int)
	}
	// Install alpine packages
	if _, err := os.Stat(os.Getenv("APK_REQUIREMENTS")); err == nil {
		cmd0 := exec.Command("apk", "update")
		_, err0 := cmd0.CombinedOutput()
		if err0 != nil {
			println("System update error!")
			println(err0.Error())
			return
		}
		cmd1 := exec.Command("paste", "-s", "-d", ",", os.Getenv("APK_REQUIREMENTS"))
		output1, err1 := cmd1.CombinedOutput()
		if err1 != nil {
			println("System requirements read error!")
			println(err1.Error())
			return
		}
		args := []string{"add", "--no-cache"}
		pkgs := strings.Split(string(output1), ",")
		args = append(args,pkgs...)
		cmd2 := exec.Command("apk", args...)
		cmd2.SysProcAttr = &syscall.SysProcAttr{}
		cmd2.SysProcAttr.Credential = &syscall.Credential{Uid: 0, Gid: 0}
		_, err2 := cmd2.CombinedOutput()
		if err2 != nil {
			println("System requirements install error!")
			println(err2.Error())
			return
		}
	}
	// Install debian packages
	if _, err := os.Stat(os.Getenv("APT_REQUIREMENTS")); err == nil {
		cmd0 := exec.Command("apt-get", "update")
		_, err0 := cmd0.CombinedOutput()
		if err0 != nil {
			println("System update error!")
			println(err0.Error())
			return
		}
		cmd1 := exec.Command("paste", "-s", "-d", ",", os.Getenv("APT_REQUIREMENTS"))
		output1, err1 := cmd1.CombinedOutput()
		if err1 != nil {
			println("System requirements read error!")
			println(err1.Error())
			return
		}
		args := []string{"install"}
		pkgs := strings.Split(string(output1)[:len(string(output1))-1] + ",-y", ",")
		args = append(args,pkgs...)
		cmd2 := exec.Command("apt", args...)
		cmd2.SysProcAttr = &syscall.SysProcAttr{}
		cmd2.SysProcAttr.Credential = &syscall.Credential{Uid: 0, Gid: 0}
		_, err2 := cmd2.CombinedOutput()
		if err2 != nil {
			println("System requirements install error!")
			println(err2.Error())
			return
		}
		cmd3 := exec.Command("apt-get", "clean")
		cmd3.SysProcAttr = &syscall.SysProcAttr{}
		cmd3.SysProcAttr.Credential = &syscall.Credential{Uid: 0, Gid: 0}
		_, err3 := cmd3.CombinedOutput()
		if err3 != nil {
			println("System requirements clean error!")
			println(err3.Error())
			return
		}
	}
}
// check if config passed in from flag name
func isFlagPassed(name string) bool {
    found := false
    flag.Visit(func(f *flag.Flag) {
        if f.Name == name {
            found = true
        }
    })
    return found
}