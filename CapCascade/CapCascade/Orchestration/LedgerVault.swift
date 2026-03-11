import Foundation

// MARK: - Persistent Score Ledger

struct TallyLedger: Codable {
    var cognomen: String
    var accruedPoints: Int
    var elapsedDuration: TimeInterval
    var epochStamp: Date
    var arenaKind: ArenaKind

    enum ArenaKind: String, Codable {
        case cascadeDuel = "cascade_duel"
        case columnStack = "column_stack"
    }
}

// MARK: - Ledger Vault (UserDefaults Persistence)

final class LedgerVault {

    static let communal = LedgerVault()

    private let vaultKey = "CapCascade_TallyLedgers"
    private let patronKey = "CapCascade_PatronName"

    private init() {}

    // MARK: - Patron Name

    func stashPatronName(_ cognomen: String) {
        UserDefaults.standard.set(cognomen, forKey: patronKey)
    }

    func retrievePatronName() -> String {
        return UserDefaults.standard.string(forKey: patronKey) ?? "Player"
    }

    // MARK: - Ledger CRUD

    func inscribeLedger(_ ledger: TallyLedger) {
        var compendium = fetchAllLedgers()
        compendium.append(ledger)
        persistCompendium(compendium)
    }

    func fetchAllLedgers() -> [TallyLedger] {
        guard let encoded = UserDefaults.standard.data(forKey: vaultKey) else {
            return []
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([TallyLedger].self, from: encoded)) ?? []
    }

    func fetchLedgers(forArena arena: TallyLedger.ArenaKind) -> [TallyLedger] {
        return fetchAllLedgers()
            .filter { $0.arenaKind == arena }
            .sorted { $0.accruedPoints > $1.accruedPoints }
    }

    func purgeAllLedgers() {
        UserDefaults.standard.removeObject(forKey: vaultKey)
    }

    private func persistCompendium(_ compendium: [TallyLedger]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(compendium) {
            UserDefaults.standard.set(encoded, forKey: vaultKey)
        }
    }
}
