import Foundation

struct PreviewData {
    static let sampleAgent = KirklandAgent(
        id: "bFonJrvPDL9xQyKzwnf18g",
        name: "Sound Planning Group",
        alias: "sound-planning-group-kirkland-2",
        source: "organic",
        location: AgentLocation(
            address1: "11411 NE 124th St",
            address2: "",
            address3: "",
            city: "Kirkland",
            state: "WA",
            zip: "98034",
            country: "US",
            latitude: 47.7104089,
            longitude: -122.1885144,
            formattedAddress: "11411 NE 124th St, Kirkland, WA 98034",
            shortAddress: "11411 NE 124th St, Kirkland"
        ),
        contact: AgentContact(
            phone: "4258219442",
            formattedPhone: "(425) 821-9442",
            websiteUrl: "https://myspg.com"
        ),
        ratings: AgentRatings(
            averageRating: 5.0,
            roundedRating: 5.0,
            reviewCount: 8
        ),
        categories: ["Financial Advising"],
        services: [
            "Wealth Management Services",
            "Trust Planning",
            "Investment Management",
            "Financial Planning Services",
            "Retirement Planning"
        ],
        photos: AgentPhotos(
            primaryPhotoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/ZICxBk4t2Y-px5ukoqthOA/ms.jpg",
            photoCount: 15,
            photoList: [
                AgentPhoto(id: "4TQfHEGcKmyPOd9Tmsj3sA", url: "https://s3-media0.fl.yelpcdn.com/bphoto/4TQfHEGcKmyPOd9Tmsj3sA/o.jpg", thumbnailUrl: nil, width: 3000, height: 4200, caption: "CJ Lovsted, CFP®")
            ]
        ),
        businessDetails: AgentBusinessDetails(
            isClosed: false,
            isChain: false,
            isYelpGuaranteed: false,
            hours: [],
            yearEstablished: 1998,
            specialties: "Income planning, investment planning, tax-forward planning",
            history: ""
        ),
        representative: AgentRepresentative(
            name: "David S.",
            bio: "Specialize in income planning, investment planning, tax-forward planning.",
            role: "Business Owner",
            photoUrl: nil
        ),
        messaging: AgentMessaging(
            isEnabled: true,
            type: "request_a_call",
            displayText: "Request a Call",
            responseTime: "within a few hours",
            replyRate: "100%"
        ),
        annotations: [
            AgentAnnotation(type: "years_in_business", title: "26 years in business")
        ],
        yelpUrls: AgentYelpURLs(
            businessUrl: "https://www.yelp.com/biz/sound-planning-group-kirkland-2",
            shareUrl: ""
        )
    )

    static let sampleAgents: [KirklandAgent] = [sampleAgent]
}
