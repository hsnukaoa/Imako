//
//  BranchDetailView.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/26.
//

import Foundation
import FirebaseAuth
import SwiftUI

struct BranchDetailView: View {
    let item: Item
    
    private var isOwner: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return item.ownerID == uid
    }
    
    @ViewBuilder
    var body: some View{
        if isOwner{
            OwnersItemView(item: item)
        }else{
            OthersItemView(item: item)
        }
    }
}

