const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.updateCropPrices = functions.pubsub.schedule("every 24 hours").onRun(async (context) => {
    const marketplaceRef = admin.firestore().collection("marketplace");
    const snapshot = await marketplaceRef.get();

    snapshot.forEach(async (doc) => {
        let data = doc.data();
        let uploadDate = data.uploadDate.toDate();
        let daysElapsed = Math.floor((Date.now() - uploadDate) / (1000 * 60 * 60 * 24));

        if (daysElapsed > 0) {
            let newPrice = data.pricePerKg * (1 - (0.05 * daysElapsed)); // 5% decrease per day
            let newFreshness = Math.max(10 - daysElapsed, 0); // Decrease freshness

            await marketplaceRef.doc(doc.id).update({
                pricePerKg: newPrice,
                freshnessScore: newFreshness
            });
        }
    });

    return null;
});
