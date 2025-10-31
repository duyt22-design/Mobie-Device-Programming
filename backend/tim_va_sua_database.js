// Script tự động tìm và sửa đường dẫn database
const fs = require('fs');
const path = require('path');

console.log('🔍 Đang tìm file database và sửa cấu hình...\n');

const backendDir = __dirname;

// Tìm tất cả file .db (loại trừ -shm và -wal)
const allFiles = fs.readdirSync(backendDir);
const dbFiles = allFiles.filter(file => 
  file.endsWith('.db') && 
  !file.includes('-shm') && 
  !file.includes('-wal')
);

console.log('📋 Tìm thấy các file database:');
if (dbFiles.length === 0) {
  console.log('   ❌ Không có file database nào!');
  process.exit(1);
}

dbFiles.forEach((file, index) => {
  const fullPath = path.join(backendDir, file);
  const stats = fs.statSync(fullPath);
  console.log(`   ${index + 1}. ${file} (${(stats.size / 1024).toFixed(2)} KB)`);
});

// Chọn file database chính (file lớn nhất hoặc file đầu tiên)
const mainDbFile = dbFiles[0];
console.log(`\n✅ Sẽ sử dụng: ${mainDbFile}\n`);

// Tìm tất cả file server*.js
const serverFiles = allFiles.filter(file => 
  file.startsWith('server') && file.endsWith('.js')
);

console.log('📋 Tìm thấy các file server:');
serverFiles.forEach((file, index) => {
  console.log(`   ${index + 1}. ${file}`);
});

// Cập nhật tất cả file server
serverFiles.forEach(serverFile => {
  const serverPath = path.join(backendDir, serverFile);
  let content = fs.readFileSync(serverPath, 'utf8');
  
  // Tìm dòng khởi tạo database
  const dbPattern = /const db = new Database\(['"]([^'"]+)['"]\);/g;
  const matches = [...content.matchAll(dbPattern)];
  
  if (matches.length > 0) {
    matches.forEach(match => {
      const oldDbName = match[1];
      if (oldDbName !== mainDbFile) {
        console.log(`\n📝 Sửa file: ${serverFile}`);
        console.log(`   Từ: ${oldDbName}`);
        console.log(`   Thành: ${mainDbFile}`);
        
        content = content.replace(dbPattern, `const db = new Database('${mainDbFile}');`);
        fs.writeFileSync(serverPath, content, 'utf8');
        
        console.log(`   ✅ Đã cập nhật!`);
      } else {
        console.log(`\n✅ File ${serverFile} đã đúng (${mainDbFile})`);
      }
    });
  } else {
    console.log(`\n⚠️  Không tìm thấy dòng khởi tạo database trong ${serverFile}`);
  }
});

console.log('\n✅ Hoàn thành!');
console.log(`\n💡 Bây giờ bạn có thể chạy backend server:`);
console.log(`   node ${serverFiles[0] || 'server_sqlite.js'}`);

