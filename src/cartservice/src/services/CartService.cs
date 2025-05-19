// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using System;
using System.Threading.Tasks;
using Grpc.Core;
using Microsoft.Extensions.Logging;
using cartservice.cartstore;
using Hipstershop;
using Microsoft.Extensions.Configuration;

namespace cartservice.services
{
    public class CartService : Hipstershop.CartService.CartServiceBase
    {
        private readonly static Empty Empty = new Empty();
        private readonly ICartStore _cartStore;
        private readonly int _extraLatency;

        public CartService(ICartStore cartStore, IConfiguration configuration)
        {
            _cartStore = cartStore;
            var latencyStr = configuration.GetValue<string>("EXTRA_LATENCY", "0ms");
            _extraLatency = ParseLatency(latencyStr);
            Console.WriteLine($"Extra latency set to {_extraLatency}ms");
        }

        private int ParseLatency(string latencyStr)
        {
            if (string.IsNullOrEmpty(latencyStr)) return 0;
            if (latencyStr.EndsWith("ms"))
            {
                if (int.TryParse(latencyStr.Substring(0, latencyStr.Length - 2), out int ms))
                {
                    return ms;
                }
            }
            else if (latencyStr.EndsWith("s"))
            {
                if (int.TryParse(latencyStr.Substring(0, latencyStr.Length - 1), out int seconds))
                {
                    return seconds * 1000;
                }
            }
            return 0;
        }

        private async Task AddLatency()
        {
            if (_extraLatency > 0)
            {
                await Task.Delay(_extraLatency);
            }
        }

        public async override Task<Empty> AddItem(AddItemRequest request, ServerCallContext context)
        {
            await AddLatency();
            await _cartStore.AddItemAsync(request.UserId, request.Item.ProductId, request.Item.Quantity);
            return Empty;
        }

        public override async Task<Cart> GetCart(GetCartRequest request, ServerCallContext context)
        {
            await AddLatency();
            return await _cartStore.GetCartAsync(request.UserId);
        }

        public async override Task<Empty> EmptyCart(EmptyCartRequest request, ServerCallContext context)
        {
            await AddLatency();
            await _cartStore.EmptyCartAsync(request.UserId);
            return Empty;
        }
    }
}