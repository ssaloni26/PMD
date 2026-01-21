import getNews from '@salesforce/apex/NewsAppController.retriveNews';
import calendarIcon from '@salesforce/resourceUrl/calendarIcon';
import defaultImage from '@salesforce/resourceUrl/defaultImage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import weatherIcon from '@salesforce/resourceUrl/weatherIcon';

import { LightningElement } from 'lwc';

export default class NewsApp extends LightningElement {
    newsList = [];
    isLoading = false;
    errorMessage = '';
    selectedCategory = 'general';
    categoryInput = ''; 
    today = '';
    weatherInfo = 'Loading...';

    calendarIcon = calendarIcon;
    weatherIcon = weatherIcon;

    // ✅ Whitelisted domains for images
    allowedDomains = [
        "abc.com", "cdn.abcotvs.com", "abcnews.go.com", "www.aljazeera.com",
        "i0.wp.com",
        "npr-brightspot.s3.amazonaws.com", "npr.brightspotcdn.com", "assets.apnews.com",
        "arc-anglerfish-washpost-prod-washpost.s3.amazonaws.com", "archaeologymag.com",
        "cdn.arstechnica.net", "assets.iflscience.com", "assets1.cbsnewsstatic.com",
        "images.axios.com", "blogger.googleusercontent.com", "assets.bwbx.io",
        "www.investors.com", "assets3.cbsnewsstatic.com", "www.cbssports.com",
        "cdn1.wionews.com", "chorus-production-cst-web.s3.us-east-1.amazonaws.com",
        "static.clubs.nfl.com", "d3i6fh83elv35t.cloudfront.net", "www.cnet.com",
        "www.cnn.com", "cdn.profootballrumors.com", "cst.brightspotcdn.com",
        "www.thedailybeast.com", "deadline.com", "dims.apnews.com",
        "cff2.earth.com", "www.esa.int", "s.espncdn.com", "ewscripps.brightspotcdn.com",
        "ewscripps-brightspot.s3.amazonaws.com", "www.federalreserve.gov",
        "ychef.files.bbci.co.uk", "imageio.forbes.com", "fortune.com",
        "cdn.mos.cms.futurecdn.net", "www.gamespot.com", "hackaday.com",
        "s.hdnux.com", "www.hollywoodreporter.com", "img.huffingtonpost.com",
        "ichef.bbci.co.uk", "assets-prd.ignimgs.com", "static0.simpleflyingimages.com",
        "indiandefencereview.com", "media.khou.com", "kotaku.com", "lifehacker.com",
        "www.livescience.com", "media.gq.com", "media-cldnry.s-nbcnews.com",
        "media.cnn.com", "platform.mmafighting.com", "nypost.com", "s3media.247sports.com",
        "www.newsnationnow.com", "images.nintendolife.com", "www.politico.com",
        "images.pushsquare.com", "pyxis.nymag.com", "www.ringsidenews.com",
        "www.rollingstone.com", "scitechdaily.com", "scx2.b-cdn.net",
        "compote.slate.com", "sportsfly.cbsistatic.com", "static0.moviewebimages.com",
        "chicago.suntimes.com", "www.tampabay.com", "techcrunch.com",
        "photos.thetrek.co", "images.timeextension.com",
        "nbc-sports-production-nbc-sports.s3.us-east-1.amazonaws.com",
        "variety.com", "platform.theverge.com", "vegoutmag.com",
        "www.washingtonpost.com", "wrestlingnews.co", "nasawatch.com"
    ];

    categories = [
        { label: 'Home', value: 'general' },
        { label: 'Business', value: 'business' },
        { label: 'Entertainment', value: 'entertainment' },
        { label: 'Health', value: 'health' },
        { label: 'Science', value: 'science' },
        { label: 'Sports', value: 'sports' },
        { label: 'Technology', value: 'technology' }
    ];

    connectedCallback() {
        this.today = new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
        this.weatherInfo = 'Sunny, 25°C';
        this.fetchNews('general');
    }

    handleInputChange(event) {
        this.categoryInput = event.detail.value;
    }

    handleSearch() {
        const category = this.categoryInput.trim().toLowerCase();
        if (!category) {
            this.showToast('Error', 'Please enter a category to search.');
        return;
        }

        const validCategories = this.categories.map(c => c.value);
        if (!validCategories.includes(category)) {
            this.showToast(
            'Invalid Category',
            `Category "${category}" not recognized. Try: ${validCategories.join(', ')}`
        );
        return;
        }

        this.selectedCategory = category;
        this.fetchNews(category);
        this.categoryInput = '';
    }

    showToast(title, message, variant = 'error') {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant, // 'success', 'error', 'warning', 'info'
        mode: 'dismissable' // optional, makes the toast closable
    });
    this.dispatchEvent(event);
}


    handleCategoryClick(event) {
        const category = event.currentTarget.dataset.value;
        this.selectedCategory = category;
        this.categoryInput = category;
        this.fetchNews(category);
    }

    fetchNews(category) {
        this.isLoading = true;
        this.newsList = [];
        this.errorMessage = '';

        getNews({ category })
    .then(result => {
        if (result && result.length) {
            this.newsList = result.map(article => ({
                ...article,
                validImageUrl: this.validateImageUrl(article.urlToImage || article.imageUrl || article.image),
                postedDate: article.publishedAt
                    ? new Date(article.publishedAt).toLocaleDateString('en-US', {
                        year: 'numeric', month: 'short', day: 'numeric'
                    })
                    : 'Date not available'
            }));
        } else {
            this.errorMessage = `Sorry, no news available for "${category}"`;
        }
    })

            .catch(error => {
                console.error(error);
                this.errorMessage = 'Error fetching news. Please try again later.';
            })
            .finally(() => this.isLoading = false);
    }

    validateImageUrl(url) {
        if (!url || !url.startsWith('http')) return defaultImage;
        try {
            const hostname = new URL(url).hostname.toLowerCase();
            const match = this.allowedDomains.some(domain => hostname.endsWith(domain.toLowerCase()));
            return match ? url : defaultImage;
        } catch (e) {
            return defaultImage;
        }
    }

    openArticle(event) {
        const url = event.currentTarget.dataset.url;
        if (url) window.open(url, '_blank');
    }

    handleImageError(event) {
        event.target.src = defaultImage;
    }



    get categoriesWithLabel() {
        return this.categories.map(cat => ({
            ...cat,
            labelWithPipe: cat.value === 'general' ? `${cat.label} |` : cat.label
        }));
    }
}