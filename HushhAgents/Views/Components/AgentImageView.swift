import SwiftUI

/// Custom image view that loads agent photos from bundled local files first,
/// then falls back to network, then shows initials placeholder.
struct AgentImageView: View {
    let candidates: [DeckImageCandidate]
    let fallbackName: String
    var fillMode: Bool = false

    @State private var loadedImage: UIImage?
    @State private var isLoading = true

    init(candidates: [DeckImageCandidate], fallbackName: String, fillMode: Bool = false) {
        self.candidates = candidates
        self.fallbackName = fallbackName
        self.fillMode = fillMode
    }

    init(url: URL?, fallbackName: String, fillMode: Bool = false) {
        if let url {
            self.candidates = [
                DeckImageCandidate(url: url, width: nil, height: nil, source: .primary)
            ]
        } else {
            self.candidates = []
        }
        self.fallbackName = fallbackName
        self.fillMode = fillMode
    }

    private var initials: String {
        let words = fallbackName.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(fallbackName.prefix(2)).uppercased()
    }

    private var loadTaskID: String {
        candidates.map(\.id).joined(separator: "|") + "|\(fallbackName)"
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                loadedImageView(image)
            } else if isLoading {
                loadingPlaceholder
            } else {
                failurePlaceholder
            }
        }
        .task(id: loadTaskID) {
            await loadImage()
        }
    }

    private var loadingPlaceholder: some View {
        Color(.secondarySystemGroupedBackground)
            .overlay {
                VStack(spacing: 8) {
                    initialsBadge
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
    }

    private var failurePlaceholder: some View {
        Color(.secondarySystemGroupedBackground)
            .overlay {
                VStack(spacing: 10) {
                    initialsBadge
                    Text(fallbackName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                }
            }
    }

    private var initialsBadge: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 90, height: 90)

            Text(initials)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private func loadedImageView(_ image: UIImage) -> some View {
        if fillMode {
            GeometryReader { geo in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        } else {
            Color(.secondarySystemGroupedBackground)
                .overlay(alignment: .top) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        .padding(.bottom, 12)
                }
                .clipped()
        }
    }

    private func loadImage() async {
        await MainActor.run {
            loadedImage = nil
            isLoading = true
        }

        guard !candidates.isEmpty else {
            await MainActor.run { isLoading = false }
            return
        }

        for candidate in candidates {
            if Task.isCancelled { return }

            if let bundledImage = findBundledImage(for: candidate) {
                await MainActor.run {
                    loadedImage = bundledImage
                    isLoading = false
                }
                return
            }

            if let remoteImage = await fetchRemoteImage(from: candidate.url) {
                await MainActor.run {
                    loadedImage = remoteImage
                    isLoading = false
                }
                return
            }
        }

        await MainActor.run { isLoading = false }
    }

    private func fetchRemoteImage(from url: URL) async -> UIImage? {
        if Task.isCancelled { return nil }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.yelp.com/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private func findBundledImage(for candidate: DeckImageCandidate) -> UIImage? {
        let urlString = candidate.url.absoluteString

        guard urlString.contains("bphoto/") else { return nil }
        let parts = urlString.components(separatedBy: "bphoto/")
        guard parts.count >= 2 else { return nil }
        let photoIdFull = parts[1].components(separatedBy: "/").first ?? ""
        let photoIdPrefix = String(photoIdFull.prefix(20))

        guard !photoIdPrefix.isEmpty else { return nil }
        guard let bundlePath = Bundle.main.resourcePath else { return nil }
        let photosDir = (bundlePath as NSString).appendingPathComponent("agent_photos")

        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: photosDir) else { return nil }

        for file in files {
            if file.contains(photoIdPrefix) {
                let fullPath = (photosDir as NSString).appendingPathComponent(file)
                if let image = UIImage(contentsOfFile: fullPath) {
                    if shouldRejectBundledImage(image, for: candidate) {
                        continue
                    }
                    return image
                }
            }
        }

        return nil
    }

    private func shouldRejectBundledImage(_ image: UIImage, for candidate: DeckImageCandidate) -> Bool {
        guard
            candidate.source == .photoList,
            let expectedMinimumDimension = candidate.minimumDimension,
            expectedMinimumDimension >= 320
        else {
            return false
        }

        let actualMinimumDimension = min(
            Int(image.size.width * image.scale),
            Int(image.size.height * image.scale)
        )

        return actualMinimumDimension < 320
    }
}
