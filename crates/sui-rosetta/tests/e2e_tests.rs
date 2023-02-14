// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use crate::rosetta_client::{get_random_sui, start_rosetta_test_server};
use sui_rosetta::operations::Operations;
use sui_sdk::rpc_types::SuiExecutionStatus;
use test_utils::network::TestClusterBuilder;

mod rosetta_client;

#[tokio::test]
async fn test_delegation() {
    let test_cluster = TestClusterBuilder::new().build().await.unwrap();
    let sender = test_cluster.accounts[0];
    let client = test_cluster.wallet.get_client().await.unwrap();
    let keystore = &test_cluster.wallet.config.keystore;
    let coin1 = get_random_sui(&client, sender, vec![]).await;

    let (rosetta_client, _handle) =
        start_rosetta_test_server(client.clone(), test_cluster.swarm.dir()).await;

    let validator = client
        .governance_api()
        .get_validators()
        .await
        .unwrap()
        .first()
        .unwrap()
        .sui_address;
    let ops = client
        .transaction_builder()
        .request_add_delegation(sender, vec![coin1.0], Some(100000), validator, None, 10000)
        .await
        .unwrap();

    let ops = Operations::try_from(ops).unwrap();

    let response = rosetta_client.rosetta_flow(ops, keystore).await;

    let tx = client
        .read_api()
        .get_transaction(response.transaction_identifier.hash)
        .await
        .unwrap();

    println!("Sui TX: {tx:?}");

    assert_eq!(SuiExecutionStatus::Success, tx.effects.status)
}
