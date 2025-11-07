-- password-content.lua
-- Quarto filter for password-protected content

local counter = 0
local include_solutions = false

-- Capture metadata early
function Meta(meta)
  if meta["include-solutions"] then
    local value = meta["include-solutions"]
    if type(value) == "boolean" then
      include_solutions = value
    elseif type(value) == "table" and value.t == "MetaBool" then
      include_solutions = value.boolean or value.bool or false
    else
      local str_value = pandoc.utils.stringify(value)
      include_solutions = (str_value == "true" or str_value == "True")
    end
  end
  return meta
end

-- Simple hash function to generate password from content
function generate_password(content_str)
  local hash = 0
  for i = 1, #content_str do
    hash = (hash * 31 + string.byte(content_str, i)) % 1000000
  end
  
  -- Convert to 5-character alphanumeric password
  local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" -- Exclude similar chars
  local password = ""
  local num = hash
  
  for i = 1, 5 do
    local idx = (num % #chars) + 1
    password = password .. string.sub(chars, idx, idx)
    num = math.floor(num / #chars)
  end
  
  return password
end

-- Generate a hash of the password for verification (not reversible)
function hash_password(password)
  local hash = 5381
  for i = 1, #password do
    hash = ((hash * 33) + string.byte(password, i)) % 4294967296
  end
  return string.format("%x", hash)
end

-- Extract text content from Pandoc blocks
function extract_text(blocks)
  local text = ""
  for _, block in ipairs(blocks) do
    if block.t == "Para" or block.t == "Plain" then
      text = text .. pandoc.utils.stringify(block)
    elseif block.t == "CodeBlock" then
      text = text .. block.text
    elseif block.t == "Header" then
      text = text .. pandoc.utils.stringify(block.content)
    elseif block.content then
      text = text .. extract_text(block.content)
    end
  end
  return text
end

-- Manual XOR implementation (compatible with all Lua versions)
function xor_bytes(a, b)
  local result = 0
  local bit_val = 1
  
  for i = 0, 7 do
    local a_bit = math.floor(a / bit_val) % 2
    local b_bit = math.floor(b / bit_val) % 2
    if a_bit ~= b_bit then
      result = result + bit_val
    end
    bit_val = bit_val * 2
  end
  
  return result
end

-- URL encode to preserve UTF-8 characters
function url_encode(str)
  local result = {}
  for i = 1, #str do
    local byte = string.byte(str, i)
    -- Keep alphanumeric and some safe characters
    if (byte >= 48 and byte <= 57) or   -- 0-9
       (byte >= 65 and byte <= 90) or   -- A-Z
       (byte >= 97 and byte <= 122) or  -- a-z
       byte == 45 or byte == 46 or byte == 95 or byte == 126 then  -- - . _ ~
      table.insert(result, string.char(byte))
    else
      table.insert(result, string.format("%%%02X", byte))
    end
  end
  return table.concat(result)
end

-- XOR-based encryption (simple but effective for this use case)
function encrypt_content(content_str, password)
  -- First URL encode to preserve UTF-8
  local encoded = url_encode(content_str)
  
  local encrypted = {}
  local key_len = #password
  
  for i = 1, #encoded do
    local char_code = string.byte(encoded, i)
    local key_code = string.byte(password, ((i - 1) % key_len) + 1)
    local encrypted_code = xor_bytes(char_code, key_code)
    table.insert(encrypted, string.format("%02x", encrypted_code))
  end
  
  return table.concat(encrypted)
end

function Div(el)
  -- Check if this is a password-protected div
  if el.classes:includes("content-password") then
    counter = counter + 1
    local div_id = "password-content-" .. counter
    
    -- Use the captured metadata value
    local show_solutions = include_solutions
    
    -- Get password name from div attributes, or use counter as fallback
    local password_name = el.attributes["name"] or ("solution-" .. counter)
    local password = generate_password(password_name)
    
    -- Render content to HTML string
    local content_html = pandoc.write(pandoc.Pandoc(el.content), 'html')
    
    if show_solutions then
      -- Show content with collapsible password info box
      local info_box = pandoc.RawBlock('html', string.format([[
<details class="password-info-box">
<summary class="password-info-summary">
🔑 Solution Password
</summary>
<div class="password-info-content">
<p class="password-display"><strong><code>%s</code></strong></p>
</div>
</details>

<style>
.password-info-box {
  background: #e7f3ff;
  border: 2px solid #0066cc;
  border-radius: 8px;
  margin: 1.5em 0;
  padding: 0;
}

.password-info-summary {
  cursor: pointer;
  padding: 1em 1.5em;
  font-weight: 600;
  color: #0066cc;
  user-select: none;
  list-style: none;
}

.password-info-summary::-webkit-details-marker {
  display: none;
}

.password-info-summary::before {
  content: '▶ ';
  display: inline-block;
  transition: transform 0.2s;
}

.password-info-box[open] .password-info-summary::before {
  transform: rotate(90deg);
}

.password-info-summary:hover {
  background: #d0e7ff;
}

.password-info-content {
  padding: 0.5em 1.5em 0.5em 1.5em;
  border-top: 1px solid #b3d9ff;
}

.password-display {
  font-size: 2.5em;
  text-align: center;
  margin: 0.3em 0;
}

.password-display code {
  background: white;
  padding: 0.1em 0.2em;
  border-radius: 6px;
  letter-spacing: 0.15em;
  color: black;
}
</style>
]], password))
      
      return {info_box, el}
    else
      -- Encrypt and hide content
      local encrypted = encrypt_content(content_html, password)
      local password_hash = hash_password(password)
      
      local html = string.format([[
<div class="password-protected-container" id="%s">
  <div class="password-prompt">
    <div class="password-box">
      <h4>🔒 Solution Locked</h4>
      <div class="password-input-group">
        <input type="text" 
               id="%s-input" 
               class="password-input" 
               placeholder="Enter 5-character password"
               maxlength="5"
               style="text-transform: uppercase;">
        <button onclick="unlockContent_%s()" class="password-submit">Unlock</button>
      </div>
      <div id="%s-error" class="password-error" style="display: none;">
        ❌ Incorrect password. Please try again.
      </div>
    </div>
  </div>
  <div id="%s-content" class="password-protected-content" style="display: none;">
    <!-- Content will be decrypted and inserted here -->
  </div>
</div>

<script>
(function() {
  const encryptedData_%s = '%s';
  const passwordHash_%s = '%s';
  
  function hashPassword(password) {
    let hash = 5381;
    for (let i = 0; i < password.length; i++) {
      hash = ((hash * 33) + password.charCodeAt(i)) >>> 0;
    }
    return hash.toString(16);
  }
  
  function xorDecrypt(hexStr, password) {
    let decrypted = '';
    const keyLen = password.length;
    
    for (let i = 0; i < hexStr.length; i += 2) {
      const charCode = parseInt(hexStr.substr(i, 2), 16);
      const keyCode = password.charCodeAt((i / 2) %% keyLen);
      decrypted += String.fromCharCode(charCode ^ keyCode);
    }
    
    // URL decode to restore UTF-8 characters
    return decodeURIComponent(decrypted);
  }
  
  window.unlockContent_%s = function() {
    const input = document.getElementById('%s-input');
    const password = input.value.toUpperCase().trim();
    const errorDiv = document.getElementById('%s-error');
    
    if (hashPassword(password) === passwordHash_%s) {
      // Decrypt and show content
      const decrypted = xorDecrypt(encryptedData_%s, password);
      document.getElementById('%s-content').innerHTML = decrypted;
      document.getElementById('%s-content').style.display = 'block';
      document.querySelector('#%s .password-prompt').style.display = 'none';
      errorDiv.style.display = 'none';
      
      // Store password for this session
      sessionStorage.setItem('%s-password', password);
    } else {
      errorDiv.style.display = 'block';
      input.value = '';
      input.focus();
    }
  };
  
  // Check if already unlocked in this session
  const savedPassword = sessionStorage.getItem('%s-password');
  if (savedPassword && hashPassword(savedPassword) === passwordHash_%s) {
    const decrypted = xorDecrypt(encryptedData_%s, savedPassword);
    document.getElementById('%s-content').innerHTML = decrypted;
    document.getElementById('%s-content').style.display = 'block';
    document.querySelector('#%s .password-prompt').style.display = 'none';
  }
  
  // Allow Enter key to submit
  document.getElementById('%s-input').addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
      unlockContent_%s();
    }
  });
})();
</script>

<style>
.password-protected-container {
  margin: 1.5em 0;
}

.password-prompt {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 200px;
}

.password-box {
  background: #f8f9fa;
  border: 2px solid #dee2e6;
  border-radius: 8px;
  padding: 2em;
  max-width: 500px;
  width: 100%%;
  text-align: center;
}

.password-box h4 {
  margin-top: 0;
  color: #495057;
}

.password-box p {
  color: #6c757d;
  margin-bottom: 1.5em;
}

.password-input-group {
  display: flex;
  gap: 0.5em;
  margin-bottom: 1em;
}

.password-input {
  flex: 1;
  padding: 0.75em;
  border: 2px solid #ced4da;
  border-radius: 4px;
  font-size: 1.1em;
  font-family: monospace;
  text-align: center;
  letter-spacing: normal;
}

.password-input:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 0.2rem rgba(0,123,255,.25);
}

.password-submit {
  padding: 0.75em 1.5em;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 600;
  transition: background-color 0.2s;
}

.password-submit:hover {
  background-color: #0056b3;
}

.password-submit:active {
  background-color: #004085;
}

.password-error {
  color: #dc3545;
  font-weight: 600;
  margin-top: 0.5em;
}

.password-protected-content {
  animation: fadeIn 0.5s;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
</style>
]], 
        div_id,           -- 1: container id
        div_id,           -- 2: input id
        counter,          -- 3: unlockContent function
        div_id,           -- 4: error div id
        div_id,           -- 5: content div id
        counter,          -- 6: encryptedData variable
        encrypted,        -- 7: encrypted data value
        counter,          -- 8: passwordHash variable
        password_hash,    -- 9: password hash value
        counter,          -- 10: unlockContent function
        div_id,           -- 11: input element id
        div_id,           -- 12: error div id
        counter,          -- 13: passwordHash variable
        counter,          -- 14: encryptedData variable
        div_id,           -- 15: content div id
        div_id,           -- 16: content div id
        div_id,           -- 17: container selector
        div_id,           -- 18: sessionStorage key
        div_id,           -- 19: sessionStorage key
        counter,          -- 20: passwordHash variable
        counter,          -- 21: encryptedData variable
        div_id,           -- 22: content div id
        div_id,           -- 23: content div id
        div_id,           -- 24: container selector
        div_id,           -- 25: input element id
        counter           -- 26: unlockContent function
      )
      
      return pandoc.RawBlock('html', html)
    end
  end
  
  return el
end

return {
  {Meta = Meta},
  {Div = Div}
}
