//
//  HomeView.swift
//  Blux
//
//  Created by Tommy on 5/16/24.
//

import SwiftUI

struct HomeView: View {
    @State var bigBanner: String = "https://image.msscdn.net/images/plan_top_img/2024051310514900000066733.jpg"
    @State var items: [Item] = [
        Item(id: "4109007", brand: "아식스", name: "젤-벤처 6 SPS", imageUrl: "https://image.msscdn.net/images/goods_img/20240507/4109007/4109007_17150597520979_500.jpg", price: 119000),
        Item(id: "3074122", brand: "슬로우애시드", name: "러스티 로고 반팔티셔츠", imageUrl: "https://image.msscdn.net/images/goods_img/20230209/3074122/3074122_16867066020814_125.jpg", price: 19500),
        Item(id: "2285512", brand: "캘빈클라인 진", name: "슬림핏 인스티튜서널", imageUrl: "https://image.msscdn.net/images/prd_img/20211229/2285512/detail_2285512_16805008310503_500.jpg", price: 31290, sale: 40),
        Item(id: "716244", brand: "반스", name: "어센티 44 DX", imageUrl: "https://image.msscdn.net/images/goods_img/20180213/716244/716244_2_125.jpg", price: 29990, sale: 68),
        Item(id: "3966892", brand: "뉴발란스", name: "UNI HERITAGE 반팔티 (WHITE)", imageUrl: "https://image.msscdn.net/images/goods_img/20240319/3966892/3966892_17119349302381_125.jpg", price: 49900),
        Item(id: "1944612", brand: "소버먼트", name: "컷 헤비 피그먼트 티셔츠-차콜-", imageUrl: "https://image.msscdn.net/images/goods_img/20210511/1944612/1944612_17153307977903_500.jpg", price: 36600, sale: 40),
    ]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        AsyncImage(url:URL(string: bigBanner)) { image in
                            image
                                .resizable()
                                .cornerRadius(10)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 380)
                            
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 380)
                                .opacity(0.4)
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        }
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lee 베스트 아이템전")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.white)
                                Text("24.05.13 - 05.26")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.white)
                            }
                            .padding(25)
                        }
                    }
                    .padding(.bottom, 30)
                    
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Blux")
                                .foregroundStyle(Color.blue)
                                .fontWeight(.bold)
                            Text("님 추천 상품")
                        }
                        .font(.title2)
                        .padding(.leading)
                        
                        
                        ScrollView(.horizontal) {
                            HStack(spacing: 20) {
                                ForEach(items, id: \.id) { item in
                                    NavigationLink(destination: WebView(url: "https://www.musinsa.com/app/goods/\(item.id)")) {
                                        
                                        VStack(alignment: .leading) {
                                            let url = URL(string: item.imageUrl)
                                            
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .frame(width: 108, height: 140)
                                            } placeholder: {
                                                ProgressView()
                                                    .tint(.white)
                                            }
                                            
                                            Text(item.brand)
                                                .font(.footnote)
                                                .fontWeight(.bold)
                                            HStack(spacing: 4) {
                                                if let sale = item.sale {
                                                    if #available(iOS 17.0, *) {
                                                        Text("\(sale)%")
                                                            .font(.footnote)
                                                            .foregroundStyle(Color.red)
                                                    } else {
                                                        // Fallback on earlier versions
                                                    }
                                                }
                                                Text("\(item.price) 원")
                                                    .font(.footnote)
                                            }
                                        }
                                    }
                                }
                                
                            }
                            .padding(.horizontal)
                            
                        }
                        .scrollIndicators(.hidden)
                        
                        
                    }
                    
                }
                .background(.white)
                .foregroundStyle(.black)
                
            }
            .scrollIndicators(.hidden)
        } else {
            // Fallback on earlier versions
        }
    }
}

#Preview {
    HomeView()
}
