const express = require('express');
const router = express.Router();
const Pharmacy = require('../models/Pharmacy');

// @route   GET /api/pharmacies/nearby
// @desc    Get pharmacies near a location
// @access  Public
router.get('/nearby', async (req, res) => {
  try {
    const { lat, lng, radius = 5000 } = req.query; // radius in meters
    
    if (!lat || !lng) {
      return res.status(400).json({ msg: 'Latitude and Longitude are required' });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);

    // In a real production app, you would use the Google Places API here:
    // const placesUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radius}&type=pharmacy&key=${process.env.GOOGLE_MAPS_API_KEY}`;
    
    // For this project, we'll use the static database but simulate distance
    const pharmacies = await Pharmacy.find();
    
    const nearbyPharmacies = pharmacies.map(p => {
      // Calculate simple distance (Haversine formula simplified for flat surface or just mock)
      const d = Math.sqrt(Math.pow(p.latitude - latitude, 2) + Math.pow(p.longitude - longitude, 2)) * 111; // approx km
      return { ...p._doc, distance: d.toFixed(1) };
    }).filter(p => p.distance <= (radius / 1000));

    res.json(nearbyPharmacies.sort((a, b) => a.distance - b.distance));
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET /api/pharmacies/search
// @desc    Search pharmacies by medicine name
// @access  Public
router.get('/search', async (req, res) => {
  try {
    const { medicine } = req.query;
    if (!medicine) {
      return res.status(400).json({ msg: 'Medicine name is required for search' });
    }

    // Use regex to find pharmacies where the medicines array contains a string matching the search query
    // This allows partial matching and case insensitivity
    const regex = new RegExp(medicine, 'i');
    
    const pharmacies = await Pharmacy.find({
      medicines: { $elemMatch: { $regex: regex } }
    });

    res.json(pharmacies);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET /api/pharmacies
// @desc    Get all pharmacies
// @access  Public
router.get('/', async (req, res) => {
    try {
        const pharmacies = await Pharmacy.find();
        res.json(pharmacies);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
