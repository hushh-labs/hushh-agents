//
//  SupabaseService.swift
//  HushhAgents
//
//  Singleton wrapper around SupabaseClient.
//

import Foundation
import Supabase

final class SupabaseService {

    // MARK: - Singleton

    static let shared = SupabaseService()

    // MARK: - Public

    let client: SupabaseClient

    // MARK: - Init

    private init() {
        let fallbackURL = "https://ibsisfnjxeowvdtvgzff.supabase.co"
        let fallbackAnonKey = "" // Set via Supabase.plist

        var supabaseURL = fallbackURL
        var supabaseAnonKey = fallbackAnonKey

        if let plistPath = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
           let plistDict = NSDictionary(contentsOfFile: plistPath) as? [String: Any] {
            if let url = plistDict["SUPABASE_URL"] as? String, !url.isEmpty {
                supabaseURL = url
            }
            if let key = plistDict["SUPABASE_ANON_KEY"] as? String, !key.isEmpty {
                supabaseAnonKey = key
            }
        }

        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL: \(supabaseURL)")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )
    }
}
