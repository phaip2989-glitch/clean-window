$ErrorActionPreference = "SilentlyContinue"

# ลิงก์ raw ของไฟล์ phaix_Clean.cmd (เปลี่ยนเป็นของคุณ)
$cmdUrl = "https://raw.githubusercontent.com/phaip2989-glitch/clean-window/main/phaix_Clean.cmd"

# โหลดเนื้อหาไฟล์มาเก็บไว้ชั่วคราว (ผู้ใช้ไม่เห็นขั้นตอนนี้)
$tmpFile = "$env:TEMP\phaix_clean_$(Get-Random).cmd"

try {
    $content = Invoke-RestMethod -Uri $cmdUrl -UseBasicParsing
    # เซฟเป็น ANSI/OEM เพื่อให้ภาษาไทยในกล่อง echo แสดงถูกต้องใน cmd
    [System.IO.File]::WriteAllText($tmpFile, $content, [System.Text.Encoding]::GetEncoding(874))
}
catch {
    Write-Host "โหลดสคริปต์ไม่สำเร็จ ตรวจสอบอินเทอร์เน็ตหรือลิงก์" -ForegroundColor Red
    exit 1
}

# รันไฟล์จริงผ่าน cmd.exe ทำให้ goto/label/pause ทำงานได้ปกติทุกปุ่ม
# -Verb RunAs = ขอสิทธิ์ Admin อัตโนมัติ (จำเป็นสำหรับ wevtutil / net stop เป็นต้น)
Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tmpFile`"" -Verb RunAs -Wait

# ลบไฟล์ชั่วคราวทิ้งหลังใช้งานเสร็จ
Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
