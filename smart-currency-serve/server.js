const express = require('express');
const cors = require('cors');
const app = express();

// السماح بالطلبات من كل الدومينات (للتجربة فقط)
app.use(cors());

// نقطة النهاية (endpoint) اللي حترجع بيانات الجنيه السوداني من Google Sheet
app.get('/sdg-rate', async (req, res) => {
  try {
    const response = await fetch('https://docs.google.com/spreadsheets/d/17gLQV0dE_rDv_WU83-FZuZCttlDUkj9nkz6LaXhduJ0/export?format=csv');
    if (!response.ok) throw new Error('Failed to fetch Google Sheet');

    const csvData = await response.text();

    // تحليل CSV (تقدر تستخدم مكتبة csv-parse لو حبيت، هنا بنعملها بطريقة يدوية بسيطة)
    const rows = csvData.split('\n').map(row => row.split(','));

    // ابحث عن سعر SDG
    let sdgRate = null;
    for (let i = 1; i < rows.length; i++) {
      if (rows[i][0].trim().toUpperCase() === 'SDG') {
        sdgRate = parseFloat(rows[i][1].replace(/,/g, ''));
        break;
      }
    }

    if (sdgRate === null) {
      return res.status(404).json({ error: 'SDG rate not found' });
    }

    res.json({ rate: sdgRate });

  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ضبط البورت
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});