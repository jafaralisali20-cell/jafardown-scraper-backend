const express = require('express');
const cors = require('cors');
const youtubedl = require('youtube-dl-exec');
const cheerio = require('cheerio');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Helper for DOM Scraping fallback (Simple metadata extraction)
async function scrapeMetadata(url) {
    try {
        const { data } = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
            }
        });
        const $ = cheerio.load(data);
        
        return {
            title: $('meta[property="og:title"]').attr('content') || $('title').text() || 'بدون عنوان',
            thumbnail: $('meta[property="og:image"]').attr('content') || null,
            description: $('meta[property="og:description"]').attr('content') || '',
        };
    } catch (e) {
        console.error('DOM Scraping Error:', e.message);
        return null;
    }
}

app.post('/api/extract', async (req, res) => {
    const { url } = req.body;
    
    if (!url) {
        return res.status(400).json({ error: 'URL is required' });
    }

    try {
        console.log(`Extracting info for: ${url}`);
        
        // Try yt-dlp first (it's much more powerful)
        let output;
        try {
            output = await youtubedl(url, {
                dumpSingleJson: true,
                noCheckCertificates: true,
                noWarnings: true,
                preferFreeFormats: true,
                addHeader: [
                    'referer:youtube.com',
                    'user-agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.75 Safari/537.36'
                ]
            });
        } catch (dlError) {
            console.warn('yt-dlp failed, attempting DOM fallback...');
            const meta = await scrapeMetadata(url);
            if (!meta) throw dlError;
            
            // Return what we found via DOM if yt-dlp fails completely
            return res.json({
                id: 'dom_scraped',
                title: meta.title,
                thumbnail: meta.thumbnail,
                extractor: 'dom_fallback',
                formats: [] // DOM scraping usually won't give direct video URLs easily without heavy logic
            });
        }

        const formats = (output.formats || []).map(f => ({
            format_id: f.format_id,
            ext: f.ext,
            resolution: f.resolution || (f.width ? `${f.width}x${f.height}` : 'audio/unknown'),
            filesize: f.filesize || f.filesize_approx,
            url: f.url,
            vcodec: f.vcodec,
            acodec: f.acodec,
            quality: f.format_note || 'unknown',
            fps: f.fps
        })).filter(f => f.url);

        res.json({
            id: output.id,
            title: output.title,
            thumbnail: output.thumbnail,
            duration: output.duration,
            extractor: output.extractor,
            formats: formats
        });

    } catch (error) {
        console.error('Extraction Error:', error);
        res.status(500).json({ 
            error: 'Failed to extract media details', 
            details: error.message 
        });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Downloader backend running on port ${PORT}`);
});
