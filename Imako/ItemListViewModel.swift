//
//  ItemListViewModel.swift
//  Imako
//
//  Created by 宇田川航太 on 2026/04/19.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class ItemListViewModel: ObservableObject{
    @Published var items: [Item] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func fetchItems(){
        stopListening()
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("items")
            .whereField("ownerID", isEqualTo: uid)
            .addSnapshotListener{ snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self.items = documents.compactMap{ doc in
                    try? doc.data(as: Item.self)
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
