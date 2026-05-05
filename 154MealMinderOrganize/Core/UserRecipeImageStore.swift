import UIKit

enum UserRecipeImageStore {
    private static let subdir = "UserRecipeImages"

    private static var folderURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = base.appending(path: subdir, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func fileURL(recipeID: String) -> URL {
        let safe = recipeID.replacingOccurrences(of: "/", with: "_")
        return folderURL.appending(path: "\(safe).jpg")
    }

    static func load(recipeID: String) -> UIImage? {
        let url = fileURL(recipeID: recipeID)
        guard FileManager.default.fileExists(atPath: url.path()) else { return nil }
        return UIImage(contentsOfFile: url.path())
    }

    @discardableResult
    static func saveJPEG(recipeID: String, image: UIImage) throws -> Bool {
        guard let data = jpegDataScaled(image, maxEdge: 1600, quality: 0.82) else { return false }
        let url = fileURL(recipeID: recipeID)
        try data.write(to: url, options: [.atomic])
        return true
    }

    static func deleteImage(recipeID: String) {
        let url = fileURL(recipeID: recipeID)
        try? FileManager.default.removeItem(at: url)
    }

    static func deleteAllStoredImages() {
        try? FileManager.default.removeItem(at: folderURL)
        _ = folderURL
    }

    private static func jpegDataScaled(_ image: UIImage, maxEdge: CGFloat, quality: CGFloat) -> Data? {
        let target = resizedImage(image, maxEdge: maxEdge) ?? image
        return target.jpegData(compressionQuality: quality)
    }

    private static func resizedImage(_ image: UIImage, maxEdge: CGFloat) -> UIImage? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let longest = max(size.width, size.height)
        guard longest > maxEdge else {
            return image.withRenderingMode(.alwaysOriginal)
        }
        let scale = maxEdge / longest
        let newSize = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
