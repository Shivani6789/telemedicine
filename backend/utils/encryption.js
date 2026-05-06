const CryptoJS = require("crypto-js");

const AES_KEY = process.env.AES_SECRET || 'my-super-secret-telemedicine-key-2026';

const encryptAES = (data) => {
    return CryptoJS.AES.encrypt(JSON.stringify(data), AES_KEY).toString();
};

const decryptAES = (ciphertext) => {
    const bytes = CryptoJS.AES.decrypt(ciphertext, AES_KEY);
    const decryptedData = bytes.toString(CryptoJS.enc.Utf8);
    return JSON.parse(decryptedData);
};

module.exports = { encryptAES, decryptAES };
