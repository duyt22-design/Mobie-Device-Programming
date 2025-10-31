// Script kiểm tra và sửa đường dẫn database sau khi đổi tên/move thư mục
const fs = require('fs');
const path = require('path');

console.log('🔍 Kiểm tra đường dẫn database...\n');

const backendDir = __dirname;
console.log(`📂 Thư mục backend: ${backendDir}\n`);

// Tìm tất cả file database
const allFiles = fs.readdirSync(backendDir);
const dbFiles = allFiles.filter(file => 
  file.endsWith('.db') && 
  !file.includes('-shm') && 
  !file.includes('-wal')
);

if (dbFiles.length === 0) {
  console.log('❌ Không tìm thấy file database nào!');
  console.log('💡 File database sẽ được tạo tự động khi chạy server lần đầu.');
  process.exit(0);
}

console.log('✅ Tìm thấy file database:');
dbFiles.forEach((file, index) => {
  const fullPath = path.join(backendDir, file);
  const exists = fs.existsSync(fullPath);
  const stats = exists ? fs.statSync(fullPath) : null;
  console.log(`   ${index + 1}. ${file}`);
  console.log(`      Đường dẫn: ${fullPath}`);
  console.log(`      Tồn tại: ${exists ? '✅' : '❌'}`);
  if (stats) {
    console.log(`      Kích thước: ${(stats.size / 1024).toFixed(2)} KB`);
  }
  console.log('');
});

// Kiểm tra file server_sqlite.js
const serverFile = path.join(backendDir, 'server_sqlite.js');
if (!fs.existsSync(serverFile)) {
  console.log('❌ Không tìm thấy server_sqlite.js!');
  process.exit(1);
}

console.log('📝 Kiểm tra cấu hình trong server_sqlite.js...\n');

let content = fs.readFileSync(serverFile, 'utf8');

// Tìm dòng khởi tạo database
const dbPattern = /const db = new Database\(['"]([^'"]+)['"]\);/;
const match = content.match(dbPattern);

if (match) {
  const configuredDb = match[1];
  console.log(`📌 Database đang cấu hình: ${configuredDb}`);
  
  // Kiểm tra file có tồn tại không
  const dbPath = path.isAbsolute(configuredDb) 
    ? configuredDb 
    : path.join(backendDir, configuredDb);
  
  const dbExists = fs.existsSync(dbPath);
  
  console.log(`   Đường dẫn đầy đủ: ${dbPath}`);
  console.log(`   Tồn tại: ${dbExists ? '✅' : '❌'}`);
  
  if (!dbExists) {
    console.log('\n⚠️  File database không tồn tại ở đường dẫn cấu hình!');
    
    // Tìm file database có sẵn
    if (dbFiles.length > 0) {
      const availableDb = dbFiles[0];
      console.log(`\n💡 Tìm thấy file database: ${availableDb}`);
      console.log(`   Đề xuất: Sử dụng ${availableDb}`);
      
      // Hỏi có muốn tự động sửa không
      console.log('\n🔧 Tự động cập nhật cấu hình? (File sẽ được sửa)');
      
      // Tự động sửa nếu file database tồn tại trong thư mục
      const suggestedPath = path.join(backendDir, availableDb);
      if (fs.existsSync(suggestedPath)) {
        console.log(`\n✅ Đang tự động cập nhật...`);
        content = content.replace(dbPattern, `const db = new Database('${availableDb}');`);
        fs.writeFileSync(serverFile, content, 'utf8');
        console.log(`✅ Đã cập nhật thành: ${availableDb}`);
      }
    }
  } else {
    console.log('\n✅ Cấu hình đúng! Database file tồn tại.');
  }
} else {
  console.log('⚠️  Không tìm thấy dòng khởi tạo database trong server_sqlite.js');
}

console.log('\n✅ Hoàn thành kiểm tra!');



