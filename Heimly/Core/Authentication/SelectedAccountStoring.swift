//
//  SelectedAccountStoring.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 30.09.2026.
//

import Foundation

nonisolated protocol SelectedAccountStoring {
    func selectedUserID(
        for serverURL: URL
    ) -> UUID?
    
    func select(
        userID: UUID,
        for serverURL: URL
    )
    
    func clearSelection(
        for serverURL: URL
    )
}
