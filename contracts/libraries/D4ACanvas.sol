// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { CanvasStorage } from "../storages/CanvasStorage.sol";
import { SettingsStorage } from "../storages/SettingsStorage.sol";
import { ID4ADrb } from "../interface/ID4ADrb.sol";

library D4ACanvas {
    error D4AInsufficientEther(uint256 required);
    error D4ACanvasAlreadyExist(bytes32 canvas_id);

    event NewCanvas(bytes32 project_id, bytes32 canvas_id, string uri);

    function createCanvas(
        mapping(bytes32 => CanvasStorage.CanvasInfo) storage _allCanvases,
        address fee_pool,
        bytes32 _project_id,
        uint256 _project_start_drb,
        uint256 canvas_num,
        string memory _canvas_uri
    )
        public
        returns (bytes32)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        {
            ID4ADrb drb = l.drb;
            uint256 cur_round = drb.currentRound();
            require(cur_round >= _project_start_drb, "project not start yet");
        }

        {
            uint256 minimal = l.create_canvas_fee;
            require(minimal <= msg.value, "not enough ether to create canvas");
            if (msg.value < minimal) revert D4AInsufficientEther(minimal);

            SafeTransferLib.safeTransferETH(fee_pool, minimal);

            uint256 exchange = msg.value - minimal;
            if (exchange > 0) SafeTransferLib.safeTransferETH(msg.sender, exchange);
        }
        bytes32 canvas_id = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        if (_allCanvases[canvas_id].exist) revert D4ACanvasAlreadyExist(canvas_id);

        {
            CanvasStorage.CanvasInfo storage ci = _allCanvases[canvas_id];
            ci.project_id = _project_id;
            ci.canvas_uri = _canvas_uri;
            ci.index = canvas_num + 1;
            l.owner_proxy.initOwnerOf(canvas_id, msg.sender);
            ci.exist = true;
        }
        emit NewCanvas(_project_id, canvas_id, _canvas_uri);
        return canvas_id;
    }
}
